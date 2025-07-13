<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.8.0, < 2.0.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 6.43.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.7 |
| <a name="requirement_tailscale"></a> [tailscale](#requirement\_tailscale) | ~> 0.21.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | 6.43.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.7.2 |
| <a name="provider_tailscale"></a> [tailscale](#provider\_tailscale) | 0.21.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_compute_disk.bastion](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_disk) | resource |
| [google_compute_disk.code](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_disk) | resource |
| [google_compute_disk.workstation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_disk) | resource |
| [google_compute_instance.bastion](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance) | resource |
| [google_compute_instance.code](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance) | resource |
| [google_compute_instance.workstation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance) | resource |
| [google_compute_router.nat_router_esw1](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router) | resource |
| [google_compute_router.nat_router_us](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router) | resource |
| [google_project_iam_member.devmesh_hub_sa_compute_instance_admin](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.devmesh_hub_sa_logging_log_writer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.devmesh_hub_sa_secret_manager_secret_accessor](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.devmesh_hub_sa_service_account_user](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_service.compute](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google_project_service.iap](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google_project_service.network_management](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google_project_service.osconfig](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google_project_service.oslogin](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google_project_service.secret_manager](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google_secret_manager_secret.tailscale_authkey](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret) | resource |
| [google_secret_manager_secret_version.tailscale_authkey](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_version) | resource |
| [google_service_account.devmesh_hub_sa](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [random_pet.global_version](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/pet) | resource |
| [tailscale_acl.as_json](https://registry.terraform.io/providers/tailscale/tailscale/latest/docs/resources/acl) | resource |
| [tailscale_dns_preferences.magic_dns](https://registry.terraform.io/providers/tailscale/tailscale/latest/docs/resources/dns_preferences) | resource |
| [tailscale_tailnet_key.nodes_auth_key](https://registry.terraform.io/providers/tailscale/tailscale/latest/docs/resources/tailnet_key) | resource |
| [tailscale_tailnet_settings.tailnet_settings](https://registry.terraform.io/providers/tailscale/tailscale/latest/docs/resources/tailnet_settings) | resource |
| [google_compute_image.debian_11](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_image) | data source |
| [google_compute_image.debian_12](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_image) | data source |
| [google_compute_image.ubuntu_2204](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_image) | data source |
| [google_compute_network.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_network) | data source |
| [google_compute_subnetwork.default_esw1](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_subnetwork) | data source |
| [google_compute_subnetwork.default_us](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_subnetwork) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_base_name"></a> [base\_name](#input\_base\_name) | Base name for DevMesh resources | `string` | `"devmesh"` | no |
| <a name="input_bastion_disk_size"></a> [bastion\_disk\_size](#input\_bastion\_disk\_size) | Size for the bastion disk | `number` | `10` | no |
| <a name="input_bastion_machine_type"></a> [bastion\_machine\_type](#input\_bastion\_machine\_type) | Machine type for the bastion instance | `string` | `"e2-micro"` | no |
| <a name="input_code_disk_size"></a> [code\_disk\_size](#input\_code\_disk\_size) | Size for the code disk | `number` | `50` | no |
| <a name="input_code_machine_type"></a> [code\_machine\_type](#input\_code\_machine\_type) | Machine type for the code server instance | `string` | `"e2-medium"` | no |
| <a name="input_debian_11_version"></a> [debian\_11\_version](#input\_debian\_11\_version) | Debian 11 image version | `string` | `"debian-11-bullseye-v20250610"` | no |
| <a name="input_debian_12_version"></a> [debian\_12\_version](#input\_debian\_12\_version) | Debian 12 image version | `string` | `"debian-12-bookworm-v20250610"` | no |
| <a name="input_default_block_size_bytes"></a> [default\_block\_size\_bytes](#input\_default\_block\_size\_bytes) | Default block size for the disks | `number` | `4096` | no |
| <a name="input_default_disk_types"></a> [default\_disk\_types](#input\_default\_disk\_types) | Default disk type for the disks | `map(string)` | <pre>{<br>  "bastion": "pd-standard",<br>  "code": "pd-balanced",<br>  "workstation": "pd-balanced"<br>}</pre> | no |
| <a name="input_default_region"></a> [default\_region](#input\_default\_region) | Default GCP region where resources are managed | `string` | `"europe-southwest1"` | no |
| <a name="input_default_zone"></a> [default\_zone](#input\_default\_zone) | Default GCP zone where resources are managed | `string` | `"europe-southwest1-b"` | no |
| <a name="input_deployer_sa_name"></a> [deployer\_sa\_name](#input\_deployer\_sa\_name) | Email of the service account to impersonate | `string` | `"devmesh-infra-admin"` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID where resources are managed | `string` | n/a | yes |
| <a name="input_tailscale_api_key"></a> [tailscale\_api\_key](#input\_tailscale\_api\_key) | API key for authenticating with Tailscale API | `string` | n/a | yes |
| <a name="input_tailscale_secret_id"></a> [tailscale\_secret\_id](#input\_tailscale\_secret\_id) | Tailscale secret ID | `string` | `"TAILSCALE_AUTHKEY"` | no |
| <a name="input_ubuntu_2204_version"></a> [ubuntu\_2204\_version](#input\_ubuntu\_2204\_version) | Ubuntu 22.04 image version | `string` | `"ubuntu-2204-jammy-v20250701"` | no |
| <a name="input_us_region"></a> [us\_region](#input\_us\_region) | US GCP region where resources are managed | `string` | `"us-east1"` | no |
| <a name="input_us_zone"></a> [us\_zone](#input\_us\_zone) | US GCP zone where resources are managed | `string` | `"us-east1-b"` | no |
| <a name="input_workstation_disk_size"></a> [workstation\_disk\_size](#input\_workstation\_disk\_size) | Size for the workstation disk | `number` | `50` | no |
| <a name="input_workstation_machine_type"></a> [workstation\_machine\_type](#input\_workstation\_machine\_type) | Machine type for the workstation instance | `string` | `"e2-standard-2"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_connection_info"></a> [connection\_info](#output\_connection\_info) | Connection information for instances |
| <a name="output_dependency_group"></a> [dependency\_group](#output\_dependency\_group) | Shared dependency group identifier for all linked resources. |
| <a name="output_disks"></a> [disks](#output\_disks) | Information about all compute disks |
| <a name="output_instances"></a> [instances](#output\_instances) | Information about all compute instances |
| <a name="output_network"></a> [network](#output\_network) | Network infrastructure information |
| <a name="output_service_account"></a> [service\_account](#output\_service\_account) | DevMesh Hub service account information |
<!-- END_TF_DOCS -->
