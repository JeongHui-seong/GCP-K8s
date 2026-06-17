# K8s VM 전용 서비스 어카운트 생성
resource "google_service_account" "k8s_vm_sa" {
  account_id   = "${var.prefix}-vm-sa"
  display_name = "K8s VM Service Account"
}

# K8s VM 전용 서비스 어카운트에 로그 작성자 권한 주입
resource "google_project_iam_member" "k8s_vm_sa_logging" {
  project = var.gcp_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.k8s_vm_sa.email}"
}

# K8s VM 전용 서비스 어카운트에 모니터링 메트릭 작성자 권한 주입
resource "google_project_iam_member" "k8s_vm_sa_monitoring" {
  project = var.gcp_project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.k8s_vm_sa.email}"
}

# K8s VM 전용 서비스 어카운트에 아티팩트 레지스트리 읽기 권한 주입
resource "google_project_iam_member" "k8s_vm_sa_artifact_registry" {
  project = var.gcp_project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.k8s_vm_sa.email}"
}

# Monitoring VM용 서비스 어카운트 생성
resource "google_service_account" "monitoring_vm_sa" {
  account_id   = "${var.prefix}-monitoring-vm-sa"
  display_name = "Monitoring VM Service Account"
}

# Monitoring VM용 서비스 어카운트에 GCP 인스턴스 조회 권한 (프로메테우스 자동 검색용)
resource "google_project_iam_member" "monitoring_vm_sa_compute_viewer" {
  project = var.gcp_project_id
  role    = "roles/compute.viewer"
  member  = "serviceAccount:${google_service_account.monitoring_vm_sa.email}"
}

# Monitoring VM용 서비스 어카운트에 모니터링 데이터 읽기 권한 (그라파나 데이터 원격 조회용)
resource "google_project_iam_member" "monitoring_vm_sa_monitoring_viewer" {
  project = var.gcp_project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.monitoring_vm_sa.email}"
}

# IAP SSH 터널링 접속 권한 부여
resource "google_project_iam_member" "user_iap_tunnel_accessor" {
  project = var.gcp_project_id
  role    = "roles/iap.tunnelResourceAccessor"
  member  = "user:${var.iap_ssh_user_email}"
}

# 앤서블 구글 IAP 플러그인이 내부 IP와 인스턴스명을 매핑할 수 있도록 메타데이터 조회 권한 부여
resource "google_project_iam_member" "user_compute_viewer" {
  project = var.gcp_project_id
  role = "roles/compute.viewer"
  member = "user:${var.iap_ssh_user_email}"
}