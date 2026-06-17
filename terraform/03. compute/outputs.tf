resource "local_file" "ansible_inventory_file" {
  filename = "${path.module}/../../ansible/hosts.ini"
  content  = <<EOF
[all:vars]
ansible_user = jgmltjd99
gcp_project = ${var.gcp_project_id}
gcp_zone = ${var.gcp_zone}

[k8s_master]
${google_compute_instance.k8s_master.name} ansible_host=${google_compute_instance.k8s_master.name}

[k8s_workers]
%{ for vm in google_compute_instance.k8s_workers ~}
${vm.name} ansible_host=${vm.name}
%{ endfor ~}

[monitoring]
${google_compute_instance.monitoring_vm.name} ansible_host=${google_compute_instance.monitoring_vm.name}

[k8s_cluster:children]
k8s_master
k8s_workers
EOF
}