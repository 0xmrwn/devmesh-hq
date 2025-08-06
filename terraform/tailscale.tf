resource "tailscale_tailnet_key" "nodes_auth_key" {
  reusable            = true
  preauthorized       = true
  ephemeral           = false
  recreate_if_invalid = "always"
  description         = "Auth key for Tailscale node authentication"
}
