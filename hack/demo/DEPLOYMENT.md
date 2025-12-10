# Grafana Dashboard Deployment - Quick Start

This guide provides a quick start for deploying Grafana dashboards using Terraform.

For comprehensive documentation, see [terraform/README.md](terraform/README.md).

## Quick Start

### Local Development

1. **Start services:**
   ```bash
   docker compose up -d
   # Grafana: http://localhost:3000 (admin/admin)
   ```

2. **Deploy dashboard:**
   ```bash
   cd hack/demo/terraform
   terraform init
   terraform apply
   ```

3. **View dashboard:**
   - Visit http://localhost:3000/d/compliance-evidence

### Making Changes

**Edit and redeploy:**
```bash
# Edit the dashboard in main.tf
vim hack/demo/terraform/main.tf

# Preview changes
terraform plan

# Apply changes
terraform apply

# Commit to Git
git add hack/demo/terraform/main.tf
git commit -m "Update dashboard configuration"
```

## Production Deployment

1. **Configure credentials:**
   ```bash
   cd hack/demo/terraform

   export TF_VAR_grafana_url="https://grafana.example.com"
   export TF_VAR_grafana_auth="Bearer YOUR_API_KEY"
   export TF_VAR_loki_url="http://loki:3100"
   ```

2. **Deploy:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Architecture

```
hack/demo/
├── terraform/           # Terraform configuration
│   ├── main.tf         # Dashboard definition (inline HCL)
│   ├── variables.tf    # Configuration variables
│   ├── outputs.tf      # Outputs
│   └── README.md       # Comprehensive guide
│
├── compose.yaml        # Docker Compose setup
├── loki-config.yaml    # Loki configuration
└── DEPLOYMENT.md       # This file
```

## Key Features

- **Infrastructure as Code**: Dashboard defined in Terraform HCL
- **Version Control**: All changes tracked in Git
- **Automated Deployment**: Deploy with `terraform apply`
- **Dynamic References**: Datasource UIDs automatically resolved
- **Multi-Environment**: Easy to deploy to dev/staging/prod

## Dashboard Panels

The Compliance Evidence Dashboard includes:

1. Total Evidence Records
2. Policy Evaluation Results (pie chart)
3. Evaluation Results Summary (table)
4. Policy Evaluation Over Time (time series)
5. Evidence by Policy Engine (donut chart)
6. Evidence by Policy Rule (donut chart)
7. Recent Evidence Records (table)
8. Evidence Logs (raw logs)

## Common Commands

```bash
# Initialize Terraform (first time)
terraform init

# Preview changes
terraform plan

# Deploy dashboard
terraform apply

# View state
terraform show

# Destroy dashboard (careful!)
terraform destroy
```

## Troubleshooting

### Dashboard not appearing

```bash
cd hack/demo/terraform
terraform state list
terraform apply
```

### Authentication errors

```bash
# Test connection
curl -u admin:admin http://localhost:3000/api/health

# Verify credentials
echo $TF_VAR_grafana_auth
```

### State issues

```bash
# Refresh state
terraform refresh

# Import existing dashboard
terraform import grafana_dashboard.compliance_evidence compliance-evidence
```

## CI/CD Integration

Example GitHub Actions workflow:

```yaml
name: Deploy Dashboards
on:
  push:
    branches: [main]
    paths: ['hack/demo/terraform/*.tf']

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: hashicorp/setup-terraform@v2

      - name: Deploy
        run: |
          cd hack/demo/terraform
          terraform init
          terraform apply -auto-approve
        env:
          TF_VAR_grafana_url: ${{ secrets.GRAFANA_URL }}
          TF_VAR_grafana_auth: ${{ secrets.GRAFANA_API_KEY }}
          TF_VAR_loki_url: ${{ vars.LOKI_URL }}
```

## Learn More

For detailed information, see:
- **[Comprehensive Guide](terraform/README.md)** - Full documentation with examples
- **[Terraform Docs](https://www.terraform.io/docs)** - Official Terraform documentation
- **[Grafana Provider](https://registry.terraform.io/providers/grafana/grafana/latest/docs)** - Provider documentation

## Migration from Docker Compose

Previously, dashboards were provisioned via Docker Compose volume mounts. Now they're managed exclusively through Terraform:

**Old (removed):**
```yaml
volumes:
  - ./hack/demo/grafana/dashboards.yaml:/etc/grafana/provisioning/dashboards/dashboards.yaml
  - ./hack/demo/grafana/dashboards:/var/lib/grafana/dashboards
```

**New (current):**
- Dashboard defined in `hack/demo/terraform/main.tf` as inline HCL
- Deploy with `terraform apply`
- Benefits: Version control, dynamic references, CI/CD integration
