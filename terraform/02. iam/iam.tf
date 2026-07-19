# 서비스 어카운트 정의
resource "google_service_account" "master_sa" {
  account_id   = "${var.prefix}-master-sa"
  display_name = "K8s Master Node Service Account"
}

resource "google_service_account" "worker_sa" {
  account_id   = "${var.prefix}-worker-sa"
  display_name = "K8s Worker Node Service Account"
}

resource "google_service_account" "monitoring_sa" {
  account_id   = "${var.prefix}-monitoring-sa"
  display_name = "Monitoring VM Service Account"
}

# Master: 토큰 관리, 자동화된 노드 관리 권한
resource "google_project_iam_member" "master_secret_manager" {
  project = var.gcp_project_id
  role    = "roles/secretmanager.secretVersionManager"
  member  = "serviceAccount:${google_service_account.master_sa.email}"
}

resource "google_project_iam_member" "master_metadata_editor" {
  project = var.gcp_project_id
  role    = "roles/compute.projectMetadataEditor"
  member  = "serviceAccount:${google_service_account.master_sa.email}"
}

# CCM 및 노드 자동 관리
resource "google_project_iam_member" "master_compute_admin" {
  project = var.gcp_project_id
  role    = "roles/compute.instanceAdmin.v1"
  member  = "serviceAccount:${google_service_account.master_sa.email}"
}

# Worker: 자동 조인 및 클러스터 관리 권한
resource "google_project_iam_member" "worker_compute_viewer" {
  project = var.gcp_project_id
  role    = "roles/compute.viewer"
  member  = "serviceAccount:${google_service_account.worker_sa.email}"
}

# 자동 조인을 위한 조인 토큰/해시 읽기 권한
resource "google_project_iam_member" "worker_secret_accessor" {
  project = var.gcp_project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.worker_sa.email}"
}

# 로그 전송
resource "google_project_iam_member" "worker_logging" {
  project = var.gcp_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.worker_sa.email}"
}

# Monitoring: 외부 백업 및 관찰 권한
resource "google_project_iam_member" "monitoring_viewer" {
  project = var.gcp_project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.monitoring_sa.email}"
}

resource "google_project_iam_member" "monitoring_compute_viewer" {
  project = var.gcp_project_id
  role    = "roles/compute.viewer"
  member  = "serviceAccount:${google_service_account.monitoring_sa.email}"
}

resource "google_project_iam_member" "monitoring_storage_admin" {
  project = var.gcp_project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.monitoring_sa.email}"
}

# 공통 IAP 접근 권한
resource "google_project_iam_member" "user_iap_access" {
  project = var.gcp_project_id
  role    = "roles/iap.tunnelResourceAccessor"
  member  = "user:${var.iap_ssh_user_email}"
}

resource "google_project_iam_member" "user_compute_viewer" {
  project = var.gcp_project_id
  role    = "roles/compute.viewer"
  member  = "user:${var.iap_ssh_user_email}"
}