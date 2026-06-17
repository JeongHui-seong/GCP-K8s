# 현 디렉토리 위치 기준으로 ansible용 host 파일 생성
resource "local_file" "ansible_inventory_file" {
  filename = "${path.module}/../ansible/hosts.ini"
  content  = <<EOF
[k8s_master]
k8s-master ansible_host=${google_compute_instance.k8s_master.network_interface[0].network_ip}

[k8s_workers]
%{ for idx, vm in google_compute_instance.k8s_workers ~}
k8s-worker-${idx + 1} ansible_host=${vm.network_interface[0].network_ip}
%{ endfor ~}

[monitoring]
monitoring-vm ansible_host=${google_compute_instance.monitoring_vm.network_interface[0].network_ip}
EOF
}