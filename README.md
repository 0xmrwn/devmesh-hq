# DevMesh HQ - Cloud Development Infrastructure

A comprehensive cloud-based development environment built on Google Cloud Platform (GCP) with secure networking via Tailscale VPN. This infrastructure provides remote access to development tools and desktop environments for distributed teams.

## 🏗️ Architecture Overview

DevMesh HQ deploys three main compute instances across two GCP regions:

### Infrastructure Components

| Component | Location | Purpose | Specifications |
|-----------|----------|---------|----------------|
| **Bastion Hub** | `us-east1-b` | Secure entry point and network hub | `e2-micro`, Ubuntu 22.04 |
| **DevMesh Code** | `europe-southwest1-b` | Development server with VS Code Server | `e2-medium`, Debian 11, 50GB |
| **DevMesh Desktop** | `europe-southwest1-b` | Remote desktop environment | `e2-standard-2`, Debian 12, 50GB |

### Key Features

- 🔒 **Secure Networking**: Tailscale VPN with MagicDNS for private mesh networking
- 💻 **Development Environment**: VS Code Server with modern toolchain (Node.js 23, Python/uv)
- 🖥️ **Remote Desktop**: XFCE desktop accessible via Chrome Remote Desktop
- 🛡️ **Security**: GCP Secret Manager integration, automatic SSL certificates
- 🌍 **Multi-Region**: Strategic deployment across US and Europe

## 🚀 Quick Start

### Prerequisites

- Google Cloud Platform account with billing enabled
- Terraform >= 1.0
- Tailscale account and auth key
- Appropriate GCP permissions for compute, networking, and secret management

### Deployment

1. **Configure Tailscale Auth Key**
   ```bash
   # Store your Tailscale auth key in GCP Secret Manager
   gcloud secrets create TAILSCALE_AUTHKEY --data-file=<(echo -n "your-tailscale-auth-key")
   ```

2. **Deploy Infrastructure**
   ```bash
   # Initialize and apply Terraform configuration
   cd terraform/
   terraform init
   terraform plan
   terraform apply
   ```

3. **Access Your Environment**
   - **Code Server**: `https://devmesh-code.<tailnet-name>:8443`
   - **Desktop**: Chrome Remote Desktop (search for "DevMesh-Madrid")
   - **SSH Access**: Via Tailscale SSH to any instance

## 📁 Project Structure

```
devmesh-hq/
├── scripts/                    # Instance startup scripts
│   ├── bastion-startup.sh     # Bastion hub configuration
│   ├── code-server-startup.sh # Development server setup
│   └── crd-startup.sh         # Chrome Remote Desktop setup
├── terraform/                 # Infrastructure as Code
│   ├── projects/devmesh-hq/   # Main project resources
│   │   ├── ComputeInstance/   # VM configurations
│   │   ├── ComputeFirewall/   # Network security rules
│   │   └── IAMServiceAccount/ # Service accounts
│   └── 344131660565/          # Shared services project
│       └── SecretManagerSecret/ # Tailscale auth key storage
└── README.md                  # This file
```

## 🛠️ Development Environment

The **DevMesh Code** instance comes pre-configured with:

### Development Tools
- **VS Code Server**: Web-based IDE accessible via HTTPS
- **Node.js 23**: Latest Node.js with npm
- **Python/uv**: Modern Python package manager
- **Git**: Version control
- **Build tools**: GCC, autotools, development headers

### Security Features
- **Automatic SSL**: Tailscale-issued certificates for HTTPS
- **Firewall Protection**: UFW configured for necessary ports
- **Secure SSH**: Tailscale SSH with identity-based authentication

## 🖥️ Remote Desktop

The **DevMesh Desktop** instance provides:

- **XFCE Desktop Environment**: Lightweight and responsive
- **Chrome Remote Desktop**: Access from any device with Chrome
- **Tailscale Integration**: Secure network connectivity
- **Automatic Registration**: Headless CRD setup

## 🔧 Configuration Details

### Network Architecture
- **VPC**: Uses default GCP networks in each region
- **Subnets**: Regional subnets with automatic IP assignment
- **NAT**: Cloud NAT for outbound internet access
- **Private IPs**: 
  - Bastion: `10.142.0.2`
  - Code Server: `10.204.0.3` 
  - Desktop: `10.204.0.2`

### Service Accounts
- **devmesh-hub-sa**: Dedicated service account with cloud platform scope

### Secrets Management
- **Tailscale Auth Key**: Stored in GCP Secret Manager
- **SSL Certificates**: Automatically provisioned by Tailscale

## 🚨 Security Considerations

1. **Network Isolation**: All instances use Tailscale for secure communication
2. **Identity-based SSH**: Leverages Tailscale's identity provider integration
3. **Encrypted Transit**: All connections use TLS/SSL
4. **Least Privilege**: Service accounts have minimal required permissions
5. **Automatic Updates**: Instances configured for security updates

## 📊 Cost Optimization

- **Right-sized Instances**: Minimal specs for each workload
- **Preemptible Options**: Consider for development environments
- **Regional Placement**: Strategic location for reduced latency
- **Auto-shutdown**: Implement schedules for non-production use

## 🔄 Maintenance

### Regular Tasks
- Monitor Tailscale connectivity and auth key rotation
- Update VS Code Server and development tools
- Review and apply security patches
- Backup important data and configurations

### Scaling
- Add additional development instances by copying terraform configurations
- Modify machine types based on workload requirements
- Implement load balancing for multiple developers (or simply use [Coder](https://coder.com/docs))

## 📚 Documentation

- [Tailscale Documentation](https://tailscale.com/docs/)
- [VS Code Server](https://github.com/coder/code-server)
- [Chrome Remote Desktop](https://support.google.com/chrome/answer/1649523)
- [GCP Compute Engine](https://cloud.google.com/compute/docs)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Test infrastructure changes in a development project
4. Submit a pull request with detailed description

## 📄 License

This project is licensed under the Unlicense - see the [LICENSE](LICENSE) file for details.

## ⚠️ Important Notes

- **Tailscale Auth Key**: Keep your auth key secure and rotate regularly
- **Cost Monitoring**: Monitor GCP usage to avoid unexpected charges
- **Data Backup**: Implement backup strategies for important development data
- **Access Control**: Review Tailscale ACLs for proper access restrictions

---
