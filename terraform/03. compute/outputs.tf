resource "local_file" "ansible_inventory_file" {
  filename = "${path.module}/../../ansible/hosts.ini"
  content  = <<EOF
[all:vars]
ansible_user = jgmltjd99
gcp_project = ${var.gcp_project_id}
gcp_zone = ${var.gcp_zone}

[k8s_master]
${google_compute_instance.k8s_master.name} ansible_host=${google_compute_instance.k8s_master.name} private_ip=${google_compute_instance.k8s_master.network_interface[0].network_ip}

[k8s_workers]
%{ for vm in google_compute_instance.k8s_workers ~}
${vm.name} ansible_host=${vm.name} private_ip=${vm.network_interface[0].network_ip}
%{ endfor ~}

[monitoring]
${google_compute_instance.monitoring_vm.name} ansible_host=${google_compute_instance.monitoring_vm.name} private_ip=${google_compute_instance.monitoring_vm.network_interface[0].network_ip}

[k8s_cluster:children]
k8s_master
k8s_workers
EOF
}

# K8s 워커 노드 그룹 ID 배출
output "k8s_workers_group_id" {
  value       = google_compute_instance_group.k8s_workers.id
  description = "로드밸런서가 가져갈 K8s 워커 인스턴스 그룹의 ID"
}

# 모니터링 VM 그룹 ID 배출
output "monitoring_group_id" {
  value       = google_compute_instance_group.monitoring_group.id
  description = "로드밸런서가 가져갈 모니터링 인스턴스 그룹의 ID"
}