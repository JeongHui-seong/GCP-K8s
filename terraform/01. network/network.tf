# VPC 생성
resource "google_compute_network" "k8s_vpc" {
  name = "${var.prefix}-vpc"
  auto_create_subnetworks = false # 보안상 커스텀 서브넷만 사용
}

# Private Subnet 생성
resource "google_compute_subnetwork" "k8s_private_subnet" {
  name = "${var.prefix}-private-subnet"
  ip_cidr_range = var.private_cidr
  region = var.gcp_region
  network = google_compute_network.k8s_vpc.id
}

# Cloud Router 생성
resource "google_compute_router" "k8s_router" {
  name = "${var.prefix}-cloud-router"
  region = var.gcp_region
  network = google_compute_network.k8s_vpc.id
}

# Cloud NAT Gateway 생성
resource "google_compute_router_nat" "k8s_nat" {
  name = "${var.prefix}-nat"
  router = google_compute_router.k8s_router.name
  region = var.gcp_region
  nat_ip_allocate_option = "AUTO_ONLY" # 자동 외부 IP 할당
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES" # VPC 내의 모든 서브넷 NAT 허용
}