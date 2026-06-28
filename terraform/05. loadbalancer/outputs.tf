output "cloudflare_dns_target_ip" {
  value       = google_compute_global_address.lb_static_ip.address
}