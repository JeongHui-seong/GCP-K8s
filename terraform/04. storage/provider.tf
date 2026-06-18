terraform {
  # 다른 컴퓨터에서 코드를 실행할 때 최소 명시한 버전 이상 사용하기 위함
  required_version = ">= 1.15.0" 

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0" 
    }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
  zone    = var.gcp_zone
}