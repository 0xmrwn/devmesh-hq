# DevMesh HQ - Cloud Development Infrastructure

A comprehensive cloud-based development environment built on Google Cloud Platform (GCP) with secure networking via Tailscale VPN. This infrastructure provides remote access to development tools and desktop environments.

> [!IMPORTANT]
> **This project was built as an experiment (running Claude Code/Gemini CLI from my iPhone). Open-sourced as-is. Deploy at your own risk.**

## Key Features

- **Secure Mesh Networking:** Tailscale VPN with MagicDNS and identity-based SSH provides strong, user-centric security.
- **Cloud-Based Development Environment:** Instantly access VS Code Server with the latest Node.js (v23), Python (with uv), and a complete modern toolchain, on any device.
- **Remote Desktop Access:** High-performance XFCE desktop available via Chrome Remote Desktop, optimized for low-latency, cross-device productivity.
- **Integrated Security:** GCP Secret Manager, automatic SSL certificates, shielded VMs, and strict access controls ensure robust protection.
- **Multi-Region Deployment:** Operates across US and European regions for high availability, low latency, and cost optimization using Always Free tier where possible.
- **Automated Provisioning:** One-command bootstrap and Terraform-driven infrastructure as code enable reproducible, auditable deployments.
- **Simple Access:** Connect to your development environment, remote desktop, or SSH without complex configuration.

##  Prerequisites

Before you begin, ensure you have the following:

- A **Google Cloud Platform (GCP) Account** with an active billing account.
- A **GCP Project ID** where resources will be provisioned. You can create a new project in the [Google Cloud Console](https://console.cloud.google.com/).
- **Terraform** version `>= 1.8.0, < 2.0.0` installed.
- **Google Cloud SDK** (`gcloud`) installed and authenticated (`gcloud auth login`).
- A **Tailscale Account** and a generated **API Access Token**.

## Deployment Procedure

Follow these steps to deploy the DevMesh HQ infrastructure.

### Step 1: Clone the Repository

Start by cloning this repository to your local machine:
```sh
git clone git@github.com:0xmrwn/devmesh-hq.git
cd devmesh-hq
```


### Step 2: Configure Tailscale ACLs

You will need to define the Access Control Lists (ACLs) for your Tailscale network to grant the appropriate permissions for users and tagged devices.

1.  **Copy the template file**:
    ```sh
    cp rules/tailscale-acl-template.jsonc rules/tailscale-acl.jsonc
    ```
2.  **Edit `rules/tailscale-acl.jsonc`** by replacing `your-tailscale-user@example.com` (line 5) with your actual Tailscale user email.
    ```jsonc
      // Define user groups - admins can manage the entire tailnet
      "groups": {
         "group:admins": [
            "your-tailscale-user@example.com" // Add your tailscale user here
         ]
      },
    ```

> [!NOTE]
> You do **not** need to paste ACLs into the Tailscale Admin Console. Terraform will manage ACLs, MagicDNS, and tailnet settings automatically.

### Step 3: Choose a Terraform Backend

You can manage your Terraform state either locally or using a remote GCS bucket. The remote backend is highly recommended for state persistence.

#### Option A: Remote Backend (Recommended)

This approach stores the Terraform state file in a dedicated Google Cloud Storage bucket, which is the standard for production infrastructure.

1.  **Create a `.env` file** from the example:
    ```sh
    cp example.env .env
    ```

2.  **Customize your `.env` file** with your GCP `PROJECT_ID` and desired `BUCKET_LOCATION`.
> [!IMPORTANT]
> Any changes made to values in `.env` must be reflected in the corresponding Terraform configuration files (`backend.tf` and `terraform.tfvars`).

3.  **Run the bootstrap script**: This script will create the GCS bucket and a dedicated service account for Terraform to use.
    ```sh
    ./init-tf.sh
    ```
    The script will prompt for confirmation before creating resources.

#### Option B: Local Backend

This is simpler for quick tests but not recommended for long-term use.

1.  **Copy the code block below and replace the contents of `terraform/backend.tf`**:

    ```hcl
    terraform {
      backend "local" {
        path = "terraform.tfstate"
      }
    }
    ```

2.  **Authenticate gcloud**: Ensure you are logged in with a user that has sufficient permissions to create the resources defined in the Terraform configuration.

### Step 4: Configure Terraform Variables

Create a `terraform.tfvars` file to provide the necessary variables for the deployment.

1.  **Create the file**:
    ```sh
    touch terraform/terraform.tfvars
    ```

2.  **Add your configuration**. You must provide your `project_id` from GCP and your **Tailscale API key**. You can also override any default values from `variables.tf`.

    ```hcl
    # terraform/terraform.tfvars

    project_id         = "your-gcp-project-id"
    tailscale_api_key  = "tskey-api-..."
    
    # Optional: Override other default variables
    # default_region       = "europe-southwest1"
    # default_zone         = "europe-southwest1-b"
    # us_region            = "us-east1"
    # us_zone              = "us-east1-b"
    ```

> [!NOTE]
> **Tailscale API Key**: The `tailscale_api_key` variable refers to a Tailscale **API access token** (generated from https://login.tailscale.com/admin/settings/keys), **not** a Tailscale Auth Key. API keys are used for managing resources via the Tailscale provider in Terraform.
>
> **Region Selection**: The default regions (`europe-southwest1`) and zones are chosen for minimal latency to European users. The US region (`us-east1`) and zone are specifically configured to take advantage of Google Cloud's Always Free tier, which provides an `e2-micro` instance at no cost when deployed in eligible US regions.


### Step 5: Deploy the Infrastructure

Once your backend and variables are configured, you can deploy the infrastructure.

1.  Navigate to the Terraform directory:
    ```sh
    cd terraform
    ```

2.  Initialize Terraform:
    ```sh
    terraform init
    ```

3.  Plan and apply the changes:
    ```sh
    terraform plan
    terraform apply
    ```

Terraform will provision the GCP resources and the Tailscale clients on each machine will automatically connect to your network.

## Architecture Overview

DevMesh HQ deploys three compute instances across two GCP regions:

| Instance        | Purpose                        | Specs                          |
|-----------------|-------------------------------|-------------------------------|
| **Bastion**     | Secure entry point            | `e2-micro`, Ubuntu 22.04, 10GB |
| **Code Server** | VS Code development environment| `e2-medium`, Debian 11, 50GB   |
| **Workstation** | Remote desktop with XFCE      | `e2-standard-2`, Debian 12, 50GB |

All instances connect via Tailscale VPN for secure networking and use the default GCP VPC with NAT gateways for internet access.

## What You Get

### Always-On Bastion
- **e2-micro instance** (Always Free eligible, US region)
- **Tailscale SSH**: Connect securely from anywhere, no public IP required
- **GCP Service Account**: Manage other instances with `gcloud`
- Acts as a **portable, always-on Google Cloud shell** for administration

### Development Environment
- **VS Code Server** with HTTPS access via Tailscale SSL certificates
- **Node.js 23** with npm and nvm
- **Python with uv** package manager
- **Git** and standard build tools

### Remote Desktop
- **XFCE desktop** environment
- **Chrome Remote Desktop** for access from any device
- Integrated with Tailscale network

### Security Features
- **Tailscale SSH** with identity-based authentication
- **Automatic SSL certificates** via Tailscale
- **GCP Secret Manager** for sensitive data
- **Shielded VMs** with secure boot and integrity monitoring

## Access

After deployment, access your infrastructure via:

- **VS Code Server**: `https://devmesh-code.{tailnet}.ts.net:8443`
- **Remote Desktop**: Setup Chrome Remote Desktop on the workstation (see setup instructions below)
- **SSH**: Use Tailscale SSH to connect to any instance

## VS Code Server Access

To access your VS Code Server for the first time:

1. SSH into the code server via Tailscale:
   ```bash
   ssh devmesh@devmesh-code.{tailnet}.ts.net
   ```

2. Retrieve the generated password:
   ```bash
   cat /home/devmesh/code-server-password.txt
   ```

3. Access VS Code Server at: `https://devmesh-code.{tailnet}.ts.net:8443`

4. Use the password from step 2 to authenticate

## Chrome Remote Desktop Setup

Chrome Remote Desktop has been installed but requires manual authorization.
To complete the setup:

1. SSH into the workstation via Tailscale:
   ```bash
   ssh devmesh@devmesh-workstation.{tailnet}.ts.net
   ```

2. Switch to the devmesh user (if not already):
   ```bash
   sudo su - devmesh
   ```

3. Go to the Chrome Remote Desktop headless setup page: https://remotedesktop.google.com/headless

4. Sign in with your Google account (the one you want to use for remote access)

5. Click "Begin" and then "Authorize"

6. Copy the command that looks like this:
   ```bash
   DISPLAY= /opt/google/chrome-remote-desktop/start-host \
   --code="4/xxxxxxxxxxxxxxxxxxxxxxxx" \
   --redirect-url="https://remotedesktop.google.com/_/oauthredirect" \
   --name=$(hostname)
   ```

7. Run that command in the SSH session

8. When prompted, set a 6-digit PIN for remote access

9. Verify the service is running:
   ```bash
   sudo systemctl status chrome-remote-desktop@devmesh
   ```

10. Connect via: https://remotedesktop.google.com/

## Cost Optimization

- Bastion instance runs on GCP's Always Free tier (`e2-micro` in US region)
- Consider stopping instances when not in use
- Use preemptible instances for development workloads

## Maintenance

- **Tailscale auth keys** should be rotated periodically (automatically recreated by Terraform when expired)
- **System updates** are not automatic; image versions are fixed in [`variables.tf`](terraform/variables.tf)
- **Backup** important development data regularly

## Documentation

- [Terraform](https://www.terraform.io/docs/)
- [Google Cloud IAM](https://cloud.google.com/iam/docs)
- [Google Cloud Storage](https://cloud.google.com/storage/docs)
- [gcloud CLI](https://cloud.google.com/sdk/gcloud)
- [Tailscale](https://tailscale.com/kb/)
- [Code Server](https://coder.com/docs/code-server/latest)

## License

This project is licensed under the Unlicense - see the [LICENSE](LICENSE) file for details.
