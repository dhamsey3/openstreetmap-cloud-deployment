# Terraform Configuration for OpenStreetMap Website Deployment

This repository contains Terraform configuration to deploy the OpenStreetMap website on AWS.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) installed on your local machine.
- AWS CLI installed and configured with appropriate permissions.
- An SSH key pair for EC2 access.

## Variables

The following variables need to be provided:

- `db_password`: The password for the PostgreSQL database.
- `db_username`: The username for the PostgreSQL database.
- `db_name`: The name of the PostgreSQL database.
- `key_name`: The name of the key pair to use for SSH access.
- `account_id`: The AWS account ID.

## Steps

1. **Initialize Terraform**:

    ```sh
    terraform init
    ```

2. **Plan the Terraform Changes**:

    ```sh
    terraform plan -var="db_password=your_db_password" -var="db_username=your_db_username" -var="db_name=your_db_name" -var="key_name=your_key_name" -var="account_id=your_account_id"
    ```

3. **Apply the Terraform Changes**:

    ```sh
    terraform apply -var="db_password=your_db_password" -var="db_username=your_db_username" -var="db_name=your_db_name" -var="key_name=your_key_name" -var="account_id=your_account_id"
    ```

Replace `your_db_password`, `your_db_username`, `your_db_name`, `your_key_name`, and `your_account_id` with your actual values.

## Configuration Details

The Terraform configuration does the following:

1. **VPC and Networking**:
    - Creates a VPC.
    - Creates a public subnet.
    - Creates an Internet Gateway and associates it with the VPC.
    - Creates a route table and associates it with the public subnet.

2. **Security Groups**:
    - Creates a security group allowing SSH (port 22) and HTTP (port 80) access.

# openstreetmap-cloud-deployment

This repository contains Terraform configuration and CI scaffolding to deploy the OpenStreetMap website to AWS. It also includes a local development setup (Docker Compose) so you can run and test the app without touching AWS.

This repo is scaffolded to deploy to ECS (Fargate) with an ALB and an RDS Postgres instance. CI builds container images and deploys them to ECS via ECR.

## Quick local development (no AWS)

Prerequisites: Docker and Docker Compose installed.

1. Start the app locally (from the root of the repo):

```bash
cd openstreetmap-website
cp config/example.storage.yml config/storage.yml
cp config/docker.database.yml config/database.yml
touch config/settings.local.yml
docker compose build
docker compose up -d
docker compose run --rm web bundle exec rails db:migrate

# Visit: http://localhost:3000
```

If you want map data, import a small PBF (Monaco is small):

```bash
wget https://download.geofabrik.de/europe/monaco-latest.osm.pbf
docker compose run --rm web osmosis \
  -verbose \
  --read-pbf monaco-latest.osm.pbf \
  --log-progress \
  --write-apidb \
    host="db" \
    database="openstreetmap" \
    user="openstreetmap" \
    validateSchemaVersion="no"
```

Tail logs if things fail:

```bash
docker compose logs -f web
docker compose logs -f db
```

## ECS deployment (Terraform + CI) — quickstart

We added Terraform scaffolding to provision ECR, an ECS cluster (Fargate), an ALB and an RDS instance. We also added a GitHub Actions workflow that builds the container image, pushes to ECR, registers a task definition, and updates the ECS service.

Important files:

- `main.tf` — existing Terraform for VPC, RDS, S3 and other resources
- `ecs_ecr.tf` — ECR repository + lifecycle policy
- `ecs_fargate.tf` — ECS cluster, ALB, task definition and service
- `ecs_outputs.tf` — helpful outputs (ECR repo URL, ALB DNS, ECS names)
- `.github/workflows/ci-ecr-deploy.yml` — CI workflow that builds/pushes image and updates ECS
- `ecs/task-definition.json` — task definition template used by CI

Required secrets for GitHub Actions (set these in the repo settings):

- `AWS_REGION` — e.g. `eu-central-1`
- `AWS_ACCOUNT_ID` — your AWS account id
- `AWS_ROLE_TO_ASSUME` (optional) — if you prefer role-based auth in Actions
- Alternatively, set `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` (less recommended)

Local Terraform quickstart (manual flow)

1. Export AWS credentials (example):

```bash
export AWS_ACCESS_KEY_ID=AKIA...
export AWS_SECRET_ACCESS_KEY=...
export AWS_DEFAULT_REGION=eu-central-1
```

2. Initialize and apply Terraform (creates ECR, ECS, ALB, RDS):

```bash
cd /workspaces/openstreetmap-cloud-deployment
terraform init
terraform plan -var-file=terraform.tfvars -out=tf.plan -input=false
terraform apply -var-file=terraform.tfvars -auto-approve
```

3. Build and push an image to ECR (or use the CI workflow):

```bash
ACCOUNT_ID=$(terraform output -raw ecr_repository_url | cut -d'.' -f1)
REGION=$(terraform output -raw ecr_repository_url | cut -d'.' -f4)
REPO_NAME=$(terraform output -raw ecr_repository_url | cut -d'/' -f2)
TAG=$(git rev-parse --short HEAD)

aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com
docker build -t ${REPO_NAME}:${TAG} -f openstreetmap-website/Dockerfile .
docker tag ${REPO_NAME}:${TAG} ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}:${TAG}
docker push ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}:${TAG}
```

4. Trigger a deployment (CI): push to `main` with required secrets set, or manually register a new task definition and force a new deployment with `aws ecs update-service --force-new-deployment`.

## Security & production notes

- RDS and ECS tasks are currently placed in public subnets in this scaffold for simplicity. For production you should move RDS into private subnets and set ECS tasks to run in private subnets too, exposing only the ALB.
- DB credentials are currently provided via `terraform.tfvars`. For production, store credentials in AWS Secrets Manager and reference them from the ECS task definition.
- Close the SSH ingress (port 22) on `web_sg` or limit it to your administrative IPs.
- Use immutable image tags (git SHA) in CI to avoid `:latest` surprises.
- Add CloudWatch/Prometheus/Grafana for monitoring and alerts.

## Next steps (I can implement)

- Wire Secrets Manager into the ECS task definition and remove DB credentials from `terraform.tfvars`.
- Move RDS to private subnets and create a NAT gateway for outbound internet (or VPC endpoints) so tasks don't require public IPs.
- Add a CI step that automatically updates the Terraform variable `image_tag` (or uses an image-based deployment strategy) to promote images to staging/production.

If you want me to proceed with any of the next steps above, tell me which one and I will implement it and run `terraform validate`/`plan` as appropriate.

---

License: see `LICENSE` in the repo.
