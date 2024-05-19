#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Initialize Terraform
terraform -chdir=terraform init

# Plan Terraform
terraform -chdir=terraform plan -out=tfplan \
  -var="key_name=$1" \
  -var="account_id=$2" \
  -var="db_password=$3" \
  -var="db_username=$4" \
  -var="db_name=$5"

# Uncomment the following line to apply the changes
# terraform -chdir=terraform apply -auto-approve tfplan
