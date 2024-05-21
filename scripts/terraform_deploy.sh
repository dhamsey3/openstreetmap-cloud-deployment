#!/bin/bash

# Ensure the script exits if any command fails
set -e

# Navigate to the terraform directory
cd "$(dirname "$0")/../terraform" || { echo "Cannot find the terraform directory"; exit 1; }

# Initialize Terraform
terraform init

# Run Terraform plan
terraform plan -var="db_password=${DB_PASSWORD}" -var="db_username=${DB_USERNAME}" -var="db_name=${DB_NAME}" -var="key_name=${KEY_NAME}" -var="account_id=${ACCOUNT_ID}"

# Commenting out the apply step for review
# Apply Terraform configuration
# terraform apply -auto-approve -var="db_password=${DB_PASSWORD}" -var="db_username=${DB_USERNAME}" -var="db_name=${DB_NAME}" -var="key_name=${KEY_NAME}" -var="account_id=${ACCOUNT_ID}"
