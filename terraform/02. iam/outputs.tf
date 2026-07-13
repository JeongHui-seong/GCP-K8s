output "master_vm_sa_email" {
  value       = google_service_account.master_sa.email
  description = "Email of the Master Node Service Account"
}

output "worker_vm_sa_email" {
  value       = google_service_account.worker_sa.email
  description = "Email of the Worker Node Service Account"
}

output "monitoring_vm_sa_email" {
  value       = google_service_account.monitoring_sa.email
  description = "Email of the Monitoring VM Service Account"
}