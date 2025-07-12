resource "google_service_account" "devmesh_hub_sa" {
  account_id   = "${var.base_name}-hub-sa"
  display_name = "DevMesh hub (e2-micro bastion)"
  project      = var.project_id
}
