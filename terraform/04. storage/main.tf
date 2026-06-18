# 백업 전용 GCS 버킷 생성
resource "google_storage_bucket" "monitoring_backup_bucket" {
    name = "${var.prefix}-monitoring-backup-${var.gcp_project_id}"
    location = var.gcp_region
    force_destroy = true
    
    # 비용 절감을 위한 10일 지난 백업 자동 삭제
    lifecycle_rule {
        condition {
            age = 10
        }
        action {
            type = "Delete"
        }
    }
}