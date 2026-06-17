output "k8s_vm_service_account_email" {
  value       = google_service_account.k8s_vm_sa.email
  description = "Email of the K8s VM Service Account"
}

output "monitoring_vm_service_account_email" {
  value       = google_service_account.monitoring_vm_sa.email
  description = "Email of the Monitoring VM Service Account"
}