#!/bin/bash
set -e

# Variables from arguments
KEY_NAME=$1
ACCOUNT_ID=$2
DB_PASSWORD=$3
DB_USERNAME=$4
DB_NAME=$5

# Change to the Terraform configuration directory
cd $(dirname "$0")/../terraform

# Initialize Terraform
terraform init

# Plan Terraform configuration
terraform plan -var "key_name=${KEY_NAME}" \
               -var "account_id=${ACCOUNT_ID}" \
               -var "db_password=${DB_PASSWORD}" \
               -var "db_username=${DB_USERNAME}" \
               -var "db_name=${DB_NAME}"
