# LocalStack Development Guide

## What is LocalStack?

LocalStack is a fully functional local AWS cloud stack that allows you to develop and test your AWS applications offline, without connecting to actual AWS services.

## Benefits

- ✅ **No AWS costs** - Test everything locally for free
- ✅ **Faster development** - No network latency to AWS
- ✅ **Safe testing** - Can't accidentally break production
- ✅ **Works offline** - No internet required
- ✅ **Rapid iteration** - Create/destroy resources instantly

## Quick Start

### 1. Start LocalStack

```bash
# Start LocalStack services
docker-compose -f docker-compose.localstack.yml up -d

# Check status
curl http://localhost:4566/_localstack/health
```

### 2. Use with Terraform

```bash
# Setup environment
chmod +x scripts/localstack-setup.sh
source scripts/localstack-setup.sh

# Rename provider file to use LocalStack
mv provider.tf provider.tf.aws.backup
mv provider.localstack.tf provider.tf

# Run Terraform
terraform init
terraform plan
terraform apply

# Restore AWS provider when done
mv provider.tf provider.localstack.tf
mv provider.tf.aws.backup provider.tf
```

### 3. Use with Ansible

```bash
cd ansible

# Test LocalStack connection
ansible-playbook localstack-test.yml

# Run other playbooks with LocalStack
ansible-playbook site.yml \
  -e "localstack_endpoint=http://localhost:4566" \
  -e "aws_region=eu-central-1"
```

### 4. Use with AWS CLI

```bash
export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=eu-central-1

# List S3 buckets
aws s3 ls

# Create ECR repository
aws ecr create-repository --repository-name openstreetmap-website

# List ECS clusters
aws ecs list-clusters
```

## Supported Services

LocalStack provides these AWS services locally:
- S3 (object storage)
- EC2 (compute instances)
- RDS (databases)
- ECS/ECR (containers)
- IAM (identity & access)
- Secrets Manager
- CloudWatch & Logs
- Application Load Balancer
- Auto Scaling

## Limitations

Some features have limited support in LocalStack:
- ❌ Multi-AZ RDS (runs as single instance)
- ❌ ACM certificate validation (auto-approved)
- ❌ Real email/SNS notifications
- ⚠️ CloudWatch metrics are mocked
- ⚠️ Some ECS features simplified

## Testing Workflow

1. **Develop locally** with LocalStack
2. **Test infrastructure** with `terraform plan/apply`
3. **Validate Ansible** playbooks
4. **Deploy to AWS** when ready

## Useful Commands

```bash
# View LocalStack logs
docker-compose -f docker-compose.localstack.yml logs -f

# Reset LocalStack (delete all data)
docker-compose -f docker-compose.localstack.yml down -v
docker-compose -f docker-compose.localstack.yml up -d

# Access LocalStack shell
docker exec -it localstack bash

# Query LocalStack resources
aws --endpoint-url=http://localhost:4566 s3 ls
aws --endpoint-url=http://localhost:4566 ec2 describe-instances
aws --endpoint-url=http://localhost:4566 ecs list-clusters
```

## Troubleshooting

### LocalStack not starting
```bash
# Check Docker is running
docker ps

# Check logs
docker logs localstack

# Restart
docker-compose -f docker-compose.localstack.yml restart
```

### Terraform errors
```bash
# Make sure using LocalStack provider
cat provider.tf | grep localhost:4566

# Check endpoints are set
env | grep AWS
```

### Resources not appearing
```bash
# LocalStack stores data in memory by default
# Restart clears everything
# To persist: add volume mount in docker-compose
```

## Cost Comparison

| Action | LocalStack | AWS |
|--------|-----------|-----|
| Testing infrastructure | Free | $10-50/day |
| Learning AWS | Free | $5-20/day |
| Development iterations | Free | Variable |
| CI/CD testing | Free | $20-100/month |

## Next Steps

1. ✅ Start LocalStack
2. ✅ Test Terraform with LocalStack
3. ✅ Test Ansible playbooks
4. ✅ Iterate and develop
5. 🚀 Deploy to real AWS when ready

For more info: https://docs.localstack.cloud/
