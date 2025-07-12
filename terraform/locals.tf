locals {
  bastion_startup_script     = file("${path.module}/scripts/bastion-startup.sh")
  code_server_startup_script = file("${path.module}/scripts/code-server-startup.sh")
  desktop_startup_script     = file("${path.module}/scripts/desktop-startup.sh")
}
