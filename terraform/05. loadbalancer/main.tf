data "terraform_remote_state" "compute" {
  backend = "gcs"
  config = {
    bucket = var.bucket_name
    prefix = "compute/state"
  }
}

# Cloudflare에 등록할 평생 고정 전면 공인 외부 IP 주소 예약
resource "google_compute_global_address" "lb_static_ip" {
  name = "${var.prefix}-jhs-domain-static-ip"
}

# 도메인 분기 처리 장치 (URL Map / L7 라우팅 테이블)
resource "google_compute_url_map" "url_map" {
  name            = "jhs-l7-url-map"
  default_service = google_compute_backend_service.k8s_worker_backend.id

  # 도메인 이름(Host)에 따라 서로 다른 백엔드로 패킷을 찢어주는 규칙
  host_rule {
    hosts        = ["shop.jhs-dev.cloud"]
    path_matcher = "shop-matcher"
  }

  host_rule {
    hosts        = ["monitor.jhs-dev.cloud"]
    path_matcher = "monitor-matcher"
  }

  host_rule {
    hosts        = ["argo.jhs-dev.cloud"]
    path_matcher = "argo-matcher"
  }

  path_matcher {
    name            = "shop-matcher"
    default_service = google_compute_backend_service.k8s_worker_backend.id
  }

  path_matcher {
    name            = "monitor-matcher"
    default_service = google_compute_backend_service.monitoring_backend.id

    # 챌린지 패스 우회용 와일드카드 규칙 추가
    path_rule {
      paths = [ "/*" ]
      service = google_compute_backend_service.monitoring_backend.id
    }
  }

  path_matcher {
    name            = "argo-matcher"
    default_service = google_compute_backend_service.k8s_worker_backend.id
  }
}

# 백엔드 서비스정의: K8s 워커 노드 그룹
resource "google_compute_backend_service" "k8s_worker_backend" {
  name        = "${var.prefix}-worker-backend-service"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 30

  # 앞서 firewall.tf에서 열어준 구글 헬스체크 링크 연동
  health_checks = [google_compute_health_check.k8s_node_health_check.id]

  # VM Instance Group 연결
  backend {
    group = data.terraform_remote_state.compute.outputs.k8s_workers_group_id
  }
}

# 백엔드 서비스 정의: 독립형 모니터링 VM
resource "google_compute_backend_service" "monitoring_backend" {
  name        = "${var.prefix}-monitoring-backend-service"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 30

  health_checks = [google_compute_health_check.monitoring_health_check.id]

# VM Instance Group 연결
  backend {
    group = data.terraform_remote_state.compute.outputs.monitoring_group_id
  }
}

# 구글 LB가 노드포트를 찔러볼 헬스체크 규칙 (K8s 인그레스용)
resource "google_compute_health_check" "k8s_node_health_check" {
  name = "${var.prefix}-node-ingress-health-check"

  http_health_check {
    # 나중에 Nginx 인그레스 컨트롤러가 수령할 노드포트 번호를 기재 (예: 30080 포트로 고정할 경우)
    port = 30080
    request_path = "/healthz" # Nginx 인그레스 자체 내장 헬스체크 경로
  }
}

# 구글 LB가 모니터링 VM을 찔러볼 헬스체크 규칙
resource "google_compute_health_check" "monitoring_health_check" {
  name = "monitoring-vm-health-check"

  http_health_check {
    port = 80 # 그라파나 기본 웹 포트가 아닌 nginx 리버스 프록시로 헬스체크
    request_path = "/healthz"
  }
}

# HTTP 외부 요청을 최종 수령하는 프런트엔드 전면 개방 문 (Forwarding Rule)
resource "google_compute_global_forwarding_rule" "http_forwarding_rule" {
  name       = "jhs-http-frontend"
  target     = google_compute_target_http_proxy.http_proxy.id
  port_range = "80"
  ip_address = google_compute_global_address.lb_static_ip.address
}

# 세 도메인 한번에 커버하는 관리형 SSL 인증서
resource "google_compute_managed_ssl_certificate" "all_certs" {
  name = "jhs-all-domains-ssl-cert"
  managed {
    domains = [
      "shop.jhs-dev.cloud",
      "monitor.jhs-dev.cloud",
      "argo.jhs-dev.cloud"
    ]
  }
}

# HTTPS 프록시 (기존 url_map 재사용)
resource "google_compute_target_https_proxy" "https_proxy" {
  name             = "jhs-https-proxy"
  url_map          = google_compute_url_map.url_map.id
  ssl_certificates = [google_compute_managed_ssl_certificate.all_certs.id]
}

# 443 포워딩 룰
resource "google_compute_global_forwarding_rule" "https_forwarding_rule" {
  name       = "jhs-https-frontend"
  target     = google_compute_target_https_proxy.https_proxy.id
  port_range = "443"
  ip_address = google_compute_global_address.lb_static_ip.address
}

# HTTP → HTTPS 리다이렉트 전용 URL Map
resource "google_compute_url_map" "http_redirect" {
  name = "jhs-http-redirect"
  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

# 기존 HTTP 프록시를 리다이렉트 전용으로 교체
resource "google_compute_target_http_proxy" "http_proxy" {
  name    = "jhs-http-proxy"
  url_map = google_compute_url_map.http_redirect.id  # 기존 url_map → http_redirect로 변경
}