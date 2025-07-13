resource "tailscale_acl" "as_json" {
  acl = local.tailscale_acl
}

resource "tailscale_dns_preferences" "magic_dns" {
  magic_dns = true
}

resource "tailscale_tailnet_settings" "tailnet_settings" {
  acls_externally_managed_on = true
  devices_auto_updates_on    = true
}

resource "tailscale_tailnet_key" "nodes_auth_key" {
  reusable            = true
  preauthorized       = true
  ephemeral           = false
  recreate_if_invalid = "always"
  description         = "Auth key for Tailscale node authentication"
}