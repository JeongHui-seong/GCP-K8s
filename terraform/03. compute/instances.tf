# 쿠버네티스 마스터 노드 생성
resource "google_compute_instance" "k8s_master" {
    name = "${var.prefix}-master"
    machine_type = var.machine_type
    zone = var.gcp_zone

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
        email = data.terraform_remote_state.iam.outputs.k8s_vm_service_account_email
        scopes = ["cloud-platform"]
    }
}

# 쿠버네티스 워커 노드 생성
resource "google_compute_instance" "k8s_workers" {
    count = 2
    name = "${var.prefix}-worker-${count.index + 1}"
    machine_type = var.machine_type
    zone = var.gcp_zone

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
        email = data.terraform_remote_state.iam.outputs.k8s_vm_service_account_email
        scopes = ["cloud-platform"]
    }
}

# 모니터링 전용 VM 인스턴스 생성
resource "google_compute_instance" "monitoring_vm" {
    name = "${var.prefix}-monitoring"
    machine_type = var.machine_type
    zone = var.gcp_zone

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
        email = data.terraform_remote_state.iam.outputs.monitoring_vm_service_account_email
        scopes = ["cloud-platform"]
    }
}