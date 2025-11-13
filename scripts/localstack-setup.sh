#!/bin/bash
# Setup script for LocalStack development environment

set -e

echo "🚀 Starting LocalStack..."
docker-compose -f docker-compose.localstack.yml up -d

echo "⏳ Waiting for LocalStack to be ready..."
timeout 60 bash -c 'until curl -s http://localhost:4566/_localstack/health | grep -q "running"; do sleep 2; done'

echo "✅ LocalStack is ready!"

# Export environment variables for Terraform
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=eu-central-1
export AWS_ENDPOINT_URL=http://localhost:4566

echo ""
echo "Environment variables set:"
echo "  AWS_ACCESS_KEY_ID=test"
echo "  AWS_SECRET_ACCESS_KEY=test"
echo "  AWS_DEFAULT_REGION=eu-central-1"
echo "  AWS_ENDPOINT_URL=http://localhost:4566"
echo ""
echo "To use with Terraform, run:"
echo "  source scripts/localstack-setup.sh"
echo "  terraform init"
echo "  terraform plan"
echo ""
echo "To stop LocalStack:"
echo "  docker-compose -f docker-compose.localstack.yml down"
