#!/usr/bin/env bash
# ----------------------------------------------------------------------
# init-tf.sh — Initialize Terraform backend infrastructure (idempotent)
# ----------------------------------------------------------------------
# This script sets up the foundational infrastructure required for
# Terraform state management in Google Cloud Platform, including:
#   • Service account for Terraform operations
#   • Cloud Storage bucket for state files with lifecycle policies
#   • IAM bindings and permissions
#
# Prerequisites:
#   • Google Cloud SDK installed and authenticated (`gcloud auth login`)
#   • gcloud SDK version ≥ 460
#   • Project with billing enabled
#   • Sufficient IAM permissions to create resources
# ----------------------------------------------------------------------

# =================================================================== #
# STAGE 1: LOAD CONFIGURATION
# =================================================================== #
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"

# Load .env file, ignoring comments and empty lines
if [[ -f "${ENV_FILE}" ]]; then
  echo "▸ Loading configuration from ${ENV_FILE}…"
  set -o allexport
  # shellcheck source=/dev/null
  source "${ENV_FILE}"
  set +o allexport
else
  echo "❌ Configuration file ${ENV_FILE} not found!"
  echo "    Please copy example.env to .env and customize the values for your deployment."
  exit 1
fi

# Validate required configuration
if [[ -z "${PROJECT_ID:-}" ]]; then
  echo "❌ PROJECT_ID is required but not set in ${ENV_FILE}"
  exit 1
fi

if [[ -z "${BUCKET_LOCATION:-}" ]]; then
  echo "❌ BUCKET_LOCATION is required but not set in ${ENV_FILE}"
  exit 1
fi

# Set internal defaults for all other values
TF_SA_NAME="devmesh-infra-admin"
BUCKET_NAME="devmesh-tf-state"
LIFECYCLE_FILE="rules/tfstate-bucket-lifecycle.json"

# Derive dependent values
TF_SA_ID="${TF_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# Handle IMPERSONATOR with fallback to current gcloud user
if [[ -z "${IMPERSONATOR:-}" ]]; then
  IMPERSONATOR="$(gcloud config get-value account)"
fi

# Display loaded configuration
echo "▸ Using configuration:"
echo "    Project ID: ${PROJECT_ID}"
echo "    Service Account: ${TF_SA_ID}"
echo "    Bucket: gs://${BUCKET_NAME}"
echo "    Location: ${BUCKET_LOCATION}"
echo "    Impersonator: ${IMPERSONATOR}"
echo ""

# Confirmation step
echo "⚠️  This script will create/modify the following resources:"
echo "    • Service Account: ${TF_SA_ID}"
echo "    • IAM roles for the service account"
echo "    • Storage bucket: gs://${BUCKET_NAME}"
echo "    • Impersonation permissions for: ${IMPERSONATOR}"
echo ""
read -p "Do you want to continue? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "❌ Operation cancelled by user."
  exit 0
fi
echo ""

# =================================================================== #
# STAGE 2: DEPLOY SERVICE ACCOUNT & IAM PERMISSIONS
# =================================================================== #
set -euo pipefail

echo "▸ Enabling core APIs (idempotent)…"
gcloud services enable iam.googleapis.com serviceusage.googleapis.com \
  cloudresourcemanager.googleapis.com --project="${PROJECT_ID}"

echo "▸ Creating service account ${TF_SA_ID} (if absent)…"
gcloud iam service-accounts describe "${TF_SA_ID}" \
  --project="${PROJECT_ID}" >/dev/null 2>&1 || \
gcloud iam service-accounts create "${TF_SA_NAME}" \
  --description="Terraform infrastructure automation service account" \
  --display-name="Devmesh Infra Admin" \
  --project="${PROJECT_ID}"

echo "▸ Granting project-level roles to SA…"
for ROLE in \
  roles/serviceusage.serviceUsageAdmin \
  roles/iam.serviceAccountAdmin \
  roles/iam.serviceAccountUser \
  roles/iam.serviceAccountTokenCreator \
  roles/compute.admin \
  roles/secretmanager.admin \
  roles/storage.admin \
  roles/resourcemanager.projectIamAdmin
do
  # Check if the binding already exists
  if ! gcloud projects get-iam-policy "${PROJECT_ID}" \
    --flatten="bindings[].members" \
    --filter="bindings.role:${ROLE}" \
    --format="value(bindings.members[])" | grep -q "serviceAccount:${TF_SA_ID}"; then
    echo "  ▸ Adding ${ROLE} to ${TF_SA_ID}…"
    gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
      --member="serviceAccount:${TF_SA_ID}" \
      --role="${ROLE}" \
      --quiet
  else
    echo "  ▸ ${ROLE} already granted to ${TF_SA_ID}, skipping…"
  fi
done

echo "▸ Allowing ${IMPERSONATOR} to impersonate the Terraform SA…"
# Check if the impersonation binding already exists
if ! gcloud iam service-accounts get-iam-policy "${TF_SA_ID}" \
  --flatten="bindings[].members" \
  --filter="bindings.role:roles/iam.serviceAccountTokenCreator" \
  --format="value(bindings.members[])" 2>/dev/null | grep -q "user:${IMPERSONATOR}"; then
  echo "  ▸ Adding impersonation permission for ${IMPERSONATOR}…"
  gcloud iam service-accounts add-iam-policy-binding "${TF_SA_ID}" \
    --member="user:${IMPERSONATOR}" \
    --role="roles/iam.serviceAccountTokenCreator" \
    --project="${PROJECT_ID}" \
    --quiet
else
  echo "  ▸ Impersonation permission already granted to ${IMPERSONATOR}, skipping…"
fi

# =================================================================== #
# STAGE 3: DEPLOY TERRAFORM BACKEND BUCKET
# =================================================================== #
echo "▸ Creating Terraform state bucket gs://${BUCKET_NAME}…"
gcloud storage buckets describe "gs://${BUCKET_NAME}" >/dev/null 2>&1 || \
gcloud storage buckets create "gs://${BUCKET_NAME}" \
  --location="${BUCKET_LOCATION}" \
  --default-storage-class=STANDARD \
  --uniform-bucket-level-access \
  --project="${PROJECT_ID}"

echo "▸ Enabling versioning on bucket…"
gcloud storage buckets update "gs://${BUCKET_NAME}" --versioning

echo "▸ Applying lifecycle configuration…"
if [[ -f "${LIFECYCLE_FILE}" ]]; then
  gcloud storage buckets update "gs://${BUCKET_NAME}" \
    --lifecycle-file="${LIFECYCLE_FILE}"
else
  echo "⚠️  Warning: ${LIFECYCLE_FILE} not found, skipping lifecycle configuration"
fi

echo "✅  Initialization complete! Configure Terraform with:"
echo "    export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=${TF_SA_ID}"
echo ""
echo "📦  Terraform backend bucket: gs://${BUCKET_NAME}"
echo "    Location: ${BUCKET_LOCATION}"
echo "    Versioning: enabled"
echo "    Lifecycle: configured (if rules file exists)"
