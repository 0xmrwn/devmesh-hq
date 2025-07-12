terraform {
  backend "gcs" {
    bucket = "devmesh-tf-state"
    prefix = "terraform/devmesh-hq"
  }
}
