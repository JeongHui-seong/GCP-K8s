variable "gcp_project_id" {
  type = string
  description = "GCP Project ID"
}

variable "gcp_region" {
  type = string
  default = "us-central1"
  description = "Primary region for resources"
}

variable "gcp_zone" {
  type = string
  default = "us-central1-a"
  description = "Primary zone for VM instances"
}

variable "prefix" {
  type = string
  default = "k8s"
}

variable "machine_type" {
  type = string
  default = "e2-standard-2"
  description = "K8s Machine type for compute instances"
}

variable "boot_image" {
  type = string
  default = "rocky-linux-cloud/rocky-linux-9"
  description = "Boot image for compute instances"
}

variable "k8s_tag_cluster" {
  type = string
  default = "k8s-cluster"
}

variable "k8s_tag_master" {
  type = string
  default = "k8s-master"
}

variable "k8s_tag_worker" {
  type = string
  default = "k8s-worker"
}

variable "k8s_tag_monitoring" {
  type = string
  default = "k8s-monitoring"
}