output "cloudflare_dns_target_ip" {
  value       = google_compute_global_address.lb_static_ip.address
  description = "이 공인 IP 주소를 Cloudflare DNS 대시보드에 shop 및 monitor A 레코드로 등록"
}