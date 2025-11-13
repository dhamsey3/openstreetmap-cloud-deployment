# Ansible for OpenStreetMap Infrastructure

This directory contains Ansible playbooks for managing operational tasks that complement the Terraform infrastructure.

## What Ansible Handles (vs Terraform)

**Terraform** = Infrastructure as Code (create/destroy AWS resources)
**Ansible** = Configuration Management & Operations (manage what runs on that infrastructure)

## Ansible Use Cases for This Project

### 1. **ECS Deployment & Rollback** (`roles/ecs_deployment/`)
- Deploy new Docker images to ECS
- Blue/green deployments
- Rollback to previous versions
- Wait for deployment health checks
- Query task/container status

### 2. **Database Operations** (`roles/database_maintenance/`)
- Create manual RDS snapshots before major changes
- Clean up old snapshots (retention policy)
- Rotate database credentials
- Export database metrics
- Run database migrations (via ECS tasks)
- Restore from backup

### 3. **Monitoring Setup** (`roles/monitoring/`)
- Deploy Prometheus + Grafana on EC2
- Configure CloudWatch metrics export
- Set up custom dashboards
- Configure alerting rules
- Install and configure exporters

### 4. **Security Hardening** (`roles/security/`)
- Scan Docker images for vulnerabilities (Trivy)
- Rotate secrets in Secrets Manager
- Update WAF rules
- Configure fail2ban on bastion hosts
- Audit logging configuration
- Compliance checks

### 5. **Disaster Recovery**
- Automated backup verification
- DR drills (restore to test environment)
- Cross-region backup replication
- Documentation generation

### 6. **Cost Optimization**
- Stop/start non-prod environments on schedule
- Resize RDS instances during off-peak
- Clean up unused resources
- Generate cost reports

### 7. **Operational Tasks**
- Health checks and smoke tests
- Cache warming after deployment
- Data imports (OSM PBF files)
- Log aggregation and analysis
- Certificate renewal automation

## Setup

1. Install Ansible and required collections:
```bash
pip install ansible boto3 botocore
ansible-galaxy collection install community.aws
ansible-galaxy collection install community.docker
```

2. Configure AWS credentials:
```bash
export AWS_ACCESS_KEY_ID=your_key
export AWS_SECRET_ACCESS_KEY=your_secret
export AWS_DEFAULT_REGION=eu-central-1
```

3. Update `inventory.ini` with your infrastructure details

4. Run playbooks:
```bash
# Deploy application
ansible-playbook -i inventory.ini site.yml --tags deploy

# Database backup
ansible-playbook -i inventory.ini site.yml --tags backup

# Security hardening
ansible-playbook -i inventory.ini site.yml --tags security

# Full monitoring stack setup
ansible-playbook -i inventory.ini site.yml --tags monitoring
```

## Example Workflows

### Deploy a new application version:
```bash
ansible-playbook -i inventory.ini site.yml --tags deploy \
  -e "task_definition_arn=arn:aws:ecs:...:task-definition/openstreetmap-task:42" \
  -e "force_deployment=true"
```

### Rotate database credentials:
```bash
ansible-playbook -i inventory.ini site.yml --tags rotation \
  -e "rotate_credentials=true"
```

### Create emergency backup:
```bash
ansible-playbook -i inventory.ini site.yml --tags backup
```

## Integration with CI/CD

You can call these playbooks from GitHub Actions:

```yaml
- name: Run Ansible deployment
  run: |
    ansible-playbook -i ansible/inventory.ini ansible/site.yml \
      --tags deploy \
      -e "task_definition_arn=${{ steps.register-task.outputs.task-definition-arn }}"
```

## What to Set Up

1. **Start with monitoring** - Get visibility first
2. **Add backup automation** - Safety net for data
3. **Security hardening** - Continuous security posture
4. **Cost optimization** - Scheduled start/stop for dev envs

## Directory Structure
```
ansible/
├── inventory.ini              # Host definitions
├── site.yml                   # Main playbook
├── ansible.cfg                # Ansible configuration
├── group_vars/                # Variables per group
│   ├── all.yml
│   └── production.yml
├── roles/
│   ├── ecs_deployment/        # ECS management
│   ├── database_maintenance/  # RDS operations
│   ├── monitoring/            # Prometheus/Grafana
│   └── security/              # Security tasks
└── files/
    └── dashboards/            # Grafana dashboards
```
