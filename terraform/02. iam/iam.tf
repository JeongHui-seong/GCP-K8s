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

# Monitoring VM용 서비스 어카운트에 Storage 파일 업로드 권한 (백업 데이터 업로드용)
resource "google_project_iam_member" "monitoring_vm_sa_storage_admin" {
  project = var.gcp_project_id
  role    = "roles/storage.objectAdmin"
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

# 쿠버네티스 클라우드 컨트롤러 전용 서비스 계정 생성
resource "google_service_account" "k8s_ccm_sa" {
  account_id   = "${var.prefix}-cloud-controller-manager"
  display_name = "Kubernetes Cloud Controller Manager Service Account"
}

# 네트워크 관리자 (로드밸런서 및 방화벽 제어)
resource "google_project_iam_member" "ccm_network_admin" {
  project = var.gcp_project_id
  role    = "roles/compute.networkAdmin"
  member  = "serviceAccount:${google_service_account.k8s_ccm_sa.email}"
}

# 컴퓨트 인스턴스 관리자 (워커 노드 인스턴스 정보 조회)
resource "google_project_iam_member" "ccm_instance_admin" {
  project = var.gcp_project_id
  role    = "roles/compute.instanceAdmin.v1"
  member  = "serviceAccount:${google_service_account.k8s_ccm_sa.email}"
}

# 서비스 계정의 인증 키(JSON) 파일 생성
resource "google_service_account_key" "ccm_key" {
  service_account_id = google_service_account.k8s_ccm_sa.name
}

# 워커 노드용 SA에 Secret Manager 접근 권한
resource "google_project_iam_member" "k8s_vm_sa_secret_accessor" {
  project = var.gcp_project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.k8s_vm_sa.email}"
}

# 워커 노드용 SA에 Compute Viewer 권한
resource "google_project_iam_member" "k8s_vm_sa_compute_viewer" {
  project = var.gcp_project_id
  role    = "roles/compute.viewer"
  member  = "serviceAccount:${google_service_account.k8s_vm_sa.email}"
}