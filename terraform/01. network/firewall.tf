# VPC 내부 통신 허용 방화벽
resource "google_compute_firewall" "allow_internal" {
  name = "${var.prefix}-allow-internal"
  network = google_compute_network.k8s_vpc.name

  allow{
    protocol = "icmp" # 핑 테스트 허용
  }
  allow {
    protocol = "tcp"
    ports = [ "0-65535" ] # K8s 통신용 VPC 내부 사설 IP끼리 모든 포트 오픈
  }
  allow {
    protocol = "udp"
    ports = [ "0-65535" ]
  }
  source_ranges = [ "${var.private_cidr}" ]
}

# 구글 IAP 터널링 접속 허용 (로컬에서 SSH 접속 및 Ansible 제어용)
resource "google_compute_firewall" "allow_iap_ssh" {
  name = "${var.prefix}-allow-iap-ssh"
  network = google_compute_network.k8s_vpc.name

  allow {
    protocol = "tcp"
    ports = [ "22" ]
  }
  source_ranges = [ "35.235.240.0/20" ] # 구글 IAP 공인 IP 대역

  target_tags = [ var.k8s_tag ]
}

# 외부 로드밸런서 및 Grafana 진입 허용 방화벽
resource "google_compute_firewall" "allow_external_ingress" {
  name = "${var.prefix}-allow-external-ingress"
  network = google_compute_network.k8s_vpc.name

  # 웹, Grafana 대시보드 포트 허용
  allow{
    protocol = "tcp"
    ports = [ "80", "443", "3000" ]
  }
  source_ranges = [ "0.0.0.0/0" ]
}

# 구글 로드밸런서 시스템(헬스체크 및 트래픽 전달) 대역 허용 규칙
resource "google_compute_firewall" "allow_gcp_lb" {
  name = "${var.prefix}-allow-gcp-lb"
  network = google_compute_network.k8s_vpc.name

  direction = "INGRESS"
  priority = 1000

  # 구글 로드밸런서가 사용하는 IP 대역
  source_ranges = [
    "35.191.0.0/16",
    "130.211.0.0/22"
  ]

  # 쿠버네티스 인그레스 노드포트 대역 및 모니터링 포트 허용
  allow {
    protocol = "tcp"
    ports = ["80", "443", "30000-32767", "9090", "3000"]
  }

  # 태그 기반 규칙 허용
  target_tags = ["k8s-cluster"]
}

# Cloudflare 프록시가 직접 붙을 때를 대비
# resource "google_compute_firewall" "allow_web_traffic" {
#   name = "${var.prefix}-allow-web-traffic"
#   network = google_compute_network.k8s_vpc.name

#   direction = "INGRESS"
#   priority = 1001
#   source_ranges = ["0.0.0.0/0"] # Cloudflare IP 대역 넣기 고려

#   allow {
#     protocol = "tcp"
#     ports = [ "80", "443" ]
#   }

#   # 태그 기반 규칙 허용
#   target_tags = ["k8s-cluster"]
# }