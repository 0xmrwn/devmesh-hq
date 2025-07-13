locals {
  # Load common functions
  common_functions = file("${path.module}/scripts/common.sh")

  # Concatenate common + specific scripts
  bastion_startup_script     = "${local.common_functions}\n${file("${path.module}/scripts/bastion-startup.sh")}"
  code_server_startup_script = "${local.common_functions}\n${file("${path.module}/scripts/code-server-startup.sh")}"
  workstation_startup_script = "${local.common_functions}\n${file("${path.module}/scripts/workstation-startup.sh")}"
}
