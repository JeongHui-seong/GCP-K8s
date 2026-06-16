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