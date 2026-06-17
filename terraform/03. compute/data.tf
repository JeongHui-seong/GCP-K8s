# gcs 백엔드에서 network, iam 값 가져오기
# network
data "terraform_remote_state" "network" {
  backend = "gcs"

  config = {
    bucket = "k8s-observability-tfstate-jhs"
    prefix = "network/state"
  }
}

# iam
data "terraform_remote_state" "iam" {
  backend = "gcs"

  config = {
    bucket = "k8s-observability-tfstate-jhs"
    prefix = "iam/state"
  }
}