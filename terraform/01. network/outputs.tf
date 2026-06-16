output "vpc_name" {
  value = google_compute_network.k8s_vpc.name
}

output "private_subnet_id" {
  value = google_compute_subnetwork.k8s_private_subnet.id
}