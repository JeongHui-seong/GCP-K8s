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

variable "iap_ssh_user_email" {
  type = string
  description = "Email of the user to grant IAP SSH tunneling access"
}