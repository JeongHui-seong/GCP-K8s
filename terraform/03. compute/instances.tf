# 쿠버네티스 마스터 노드 생성
resource "google_compute_instance" "k8s_master" {
    name = "${var.prefix}-master"
    machine_type = var.machine_type
    zone = var.gcp_zone

    tags = [ var.k8s_tag_cluster, var.k8s_tag_master ]

    boot_disk {
        initialize_params {
            image = var.boot_image
            size = 50
        }
    }

    network_interface {
        subnetwork = data.terraform_remote_state.network.outputs.private_subnet_id
    }

    service_account {
        email = data.terraform_remote_state.iam.outputs.master_vm_sa_email
        scopes = ["cloud-platform"]
    }
}

# 인스턴스 템플릿 (워커 노드용)
resource "google_compute_instance_template" "k8s_worker_template" {
  name_prefix  = "${var.prefix}-worker-template"
  machine_type = var.machine_type
  tags         = [ var.k8s_tag_cluster, var.k8s_tag_worker ]

  depends_on = [ google_compute_instance.k8s_master ]

  disk {
    auto_delete  = true
    boot         = true
    source_image = var.boot_image
    disk_size_gb = 50
  }

  network_interface {
    subnetwork = data.terraform_remote_state.network.outputs.private_subnet_id
  }

  service_account {
    email  = data.terraform_remote_state.iam.outputs.worker_vm_sa_email
    scopes = ["cloud-platform"]
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash

    # 시스템 업데이트 및 필수 패키지 설치
    dnf update -y
    # EPEL 저장소 및 Ansible 설치를 위한 도구들
    dnf install -y epel-release
    dnf install -y ansible-core git nmap-ncat

    # Ansible 설정 및 pull (워커 노드 구성)
    ansible-pull -U https://github.com/JeongHui-seong/GCP-K8s.git -i localhost, -f ansible/worker-setup.yml

    # 마스터 노드 준비 대기 (6443 포트 체크)
    MASTER_IP="${google_compute_instance.k8s_master.network_interface[0].network_ip}"
    echo "Waiting for master node at $MASTER_IP:6443..."

    for i in {1..30}; do
      if nc -zv $MASTER_IP 6443 > /dev/null 2>&1; then
        echo "Master node is ready!"
        break
      fi
      echo "Waiting for master node... ($i/30)"
      sleep 20
    done

    # 토큰으로 조인
    TOKEN=$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/attributes/k8s-join-token" \
             -H "Metadata-Flavor: Google")

    kubeadm join $MASTER_IP:6443 --token $TOKEN --discovery-token-unsafe-do-not-use-ca-hash
  EOF
}

# MIG (Managed Instance Group)
resource "google_compute_region_instance_group_manager" "k8s_workers_mig" {
  name = "${var.prefix}-workers-mig"
  base_instance_name = "${var.prefix}-worker"
  version {
    instance_template = google_compute_instance_template.k8s_worker_template.id
  }
  target_size = 2 # 기본 노드 수
}

# 오토스케일러
resource "google_compute_region_autoscaler" "k8s_workers_autoscaler" {
  name   = "${var.prefix}-workers-autoscaler"
  target = google_compute_region_instance_group_manager.k8s_workers_mig.id
  autoscaling_policy {
    max_replicas    = 3
    min_replicas    = 2
    cpu_utilization {
      target = 0.5 # CPU 50% 도달 시 스케일 아웃
    }
  }
}

# 모니터링 전용 VM 인스턴스 생성
resource "google_compute_instance" "monitoring_vm" {
    name = "${var.prefix}-monitoring"
    machine_type = var.machine_type
    zone = var.gcp_zone

    tags = [ var.k8s_tag_monitoring, var.k8s_tag_cluster ]

    boot_disk {
        initialize_params {
            image = var.boot_image
            size = 100
        }
    }

    network_interface {
        subnetwork = data.terraform_remote_state.network.outputs.private_subnet_id
    }

    service_account {
        email = data.terraform_remote_state.iam.outputs.monitoring_vm_sa_email
        scopes = ["cloud-platform"]
    }
}

# 독립형 모니터링 VM을 인스턴스 그룹으로 묶음
resource "google_compute_instance_group" "monitoring_group" {
  name        = "monitoring-vm-group"
  zone        = var.gcp_zone

  instances = [
    google_compute_instance.monitoring_vm.self_link
  ]

  named_port {
    name = "grafana"
    port = 3000 # 그라파나 기본 포트
  }
}