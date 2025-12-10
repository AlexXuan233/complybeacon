# Grafana Dashboard Management with Terraform

Complete guide for managing Grafana dashboards using Infrastructure as Code (Terraform).

## Table of Contents

1. [Overview](#overview)
2. [What is Terraform?](#what-is-terraform)
3. [Quick Start](#quick-start)
4. [Local Development](#local-development)
5. [Production Deployment](#production-deployment)
6. [Dashboard Management](#dashboard-management)
7. [Advanced Features](#advanced-features)
8. [CI/CD Integration](#cicd-integration)
9. [Troubleshooting](#troubleshooting)
10. [Migration Guide](#migration-guide)

---

## Overview

This project uses Terraform to manage Grafana dashboards, providing version control, automated deployments, and infrastructure as code capabilities.

### Directory Structure

```
hack/demo/
├── terraform/                         # Terraform-managed infrastructure
│   ├── main.tf                        # Main configuration (includes inline dashboard)
│   ├── variables.tf                   # Variables
│   ├── outputs.tf                     # Outputs
│   ├── IMPORT.md                      # Import instructions
│   └── README.md                      # This file
│
├── demo-config.yaml                   # OpenTelemetry config
├── loki-config.yaml                   # Loki config
└── DEPLOYMENT.md                      # Quick start guide
```

### Key Benefits

- **Version Control**: All changes tracked in Git
- **Code Review**: Dashboard changes go through PR process
- **Automated Deployment**: CI/CD integration
- **Multi-Environment**: Deploy same dashboards to dev/staging/prod
- **Rollback**: Easy to revert using Git
- **State Management**: Terraform tracks what's deployed
- **Dynamic References**: Datasource UIDs automatically resolved
- **Documentation**: Infrastructure as code is self-documenting

---

## What is Terraform?

Terraform is an **Infrastructure as Code (IaC)** tool that lets you manage infrastructure through code rather than manual processes.

### Why Use Terraform for Grafana Dashboards?

**Traditional Approach (Manual):**
```
┌─────────────────────────────────────────┐
│ 1. Open Grafana UI                      │
│ 2. Click "Create Dashboard"             │
│ 3. Add panels one by one                │
│ 4. Configure queries manually           │
│ 5. Save dashboard                       │
│                                         │
│ Problems:                                │
│ ❌ Hard to replicate                     │
│ ❌ No version control                    │
│ ❌ Manual errors                         │
│ ❌ Team members make conflicting changes │
│ ❌ Can't automate                        │
└─────────────────────────────────────────┘
```

**Terraform Approach (Automated):**
```
┌─────────────────────────────────────────┐
│ 1. Write dashboard config in HCL code  │
│ 2. Commit to Git                        │
│ 3. Run: terraform apply                 │
│                                         │
│ Benefits:                                │
│ ✅ Repeatable across environments        │
│ ✅ Version controlled in Git             │
│ ✅ Automated and consistent              │
│ ✅ Code review process                   │
│ ✅ CI/CD integration                     │
│ ✅ Dynamic datasource references         │
└─────────────────────────────────────────┘
```

### How Terraform Works

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Write      │     │   Preview    │     │    Apply     │
│   Config     │────▶│   Changes    │────▶│   Changes    │
│              │     │              │     │              │
│  main.tf     │     │ terraform    │     │  terraform   │
│              │     │   plan       │     │   apply      │
└──────────────┘     └──────────────┘     └──────────────┘
                            │
                            │ Shows what will change:
                            ▼
                     + Create dashboard
                     ~ Update panel query
                     - Delete old panel
```

**The Workflow:**

1. **Write** configuration in `main.tf`
2. **Initialize**: `terraform init` (downloads providers)
3. **Plan**: `terraform plan` (preview changes)
4. **Apply**: `terraform apply` (make changes)

---

## Quick Start

### Prerequisites

1. Terraform installed (>= 1.0) - [Download](https://www.terraform.io/downloads)
2. Grafana running and accessible
3. Loki datasource available

### Basic Commands

```bash
cd hack/demo/terraform

# Initialize Terraform (first time only)
terraform init

# Preview changes
terraform plan

# Deploy the dashboard
terraform apply

# Destroy resources (if needed)
terraform destroy
```

---

## Local Development

### 1. Start Services with Docker Compose

```bash
# From the project root
docker compose up -d

# Grafana will be available at http://localhost:3000
# Default credentials: admin/admin
```

**Note**: Dashboards are managed by Terraform, not auto-provisioned by Docker Compose.

### 2. Deploy Dashboard with Terraform

```bash
cd hack/demo/terraform

# Initialize (first time only)
terraform init

# Preview changes
terraform plan

# Deploy
terraform apply
```

The dashboard will be created at http://localhost:3000/d/compliance-evidence.

### 3. Making Changes

**Option 1: Edit Terraform HCL (Recommended)**

1. Edit the dashboard definition in `main.tf`
2. Run `terraform plan` to preview changes
3. Run `terraform apply` to deploy changes
4. Commit to Git

**Option 2: Export from Grafana UI**

1. Make changes in Grafana UI
2. Export dashboard JSON from Grafana
3. Convert JSON to HCL format
4. Update `main.tf`
5. Run `terraform apply`
6. Commit the changes to Git

---

## Production Deployment

### Prerequisites

1. Terraform installed (v1.0+)
2. Grafana instance running and accessible
3. Grafana API credentials (admin:password or API key)
4. Loki instance configured as data source

### Configuration

You can configure Terraform using variables:

**Method 1: Command Line**

```bash
terraform apply \
  -var="grafana_url=https://grafana.example.com" \
  -var="grafana_auth=admin:password" \
  -var="loki_url=http://loki:3100"
```

**Method 2: terraform.tfvars File**

```bash
cat > terraform.tfvars <<EOF
grafana_url  = "https://grafana.example.com"
grafana_auth = "admin:password"
loki_url     = "http://loki:3100"
EOF

terraform apply
```

**Method 3: Environment Variables**

```bash
export TF_VAR_grafana_url="https://grafana.example.com"
export TF_VAR_grafana_auth="admin:password"
export TF_VAR_loki_url="http://loki:3100"

terraform apply
```

### Using API Keys (Recommended)

Instead of username:password, use Grafana API keys for production:

1. **Create API key in Grafana:**
   - Go to Configuration → API Keys
   - Click "New API Key"
   - Set role to "Admin"
   - Copy the key

2. **Use the API key:**

```bash
# Via command line
terraform apply -var="grafana_auth=Bearer YOUR_API_KEY_HERE"

# Or via environment variable
export TF_VAR_grafana_auth="Bearer YOUR_API_KEY_HERE"
terraform apply
```

### Remote State Management

For production, use remote state storage:

```hcl
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "grafana/dashboards/terraform.tfstate"
    region = "us-east-1"
  }
}
```

Or use Terraform Cloud:

```hcl
terraform {
  cloud {
    organization = "my-org"
    workspaces {
      name = "grafana-dashboards"
    }
  }
}
```

---

## Dashboard Management

### Inline HCL Approach

Dashboards are defined inline using HCL in `main.tf`:

```hcl
resource "grafana_dashboard" "compliance_evidence" {
  overwrite = true

  config_json = jsonencode({
    title = "Compliance Evidence Dashboard"
    uid   = "compliance-evidence"

    panels = [
      {
        id    = 1
        title = "Total Evidence Records"
        type  = "stat"
        datasource = {
          type = "loki"
          uid  = grafana_data_source.loki.uid  # Dynamic reference!
        }
        targets = [{
          expr = "sum(count_over_time({service_name=~\".+\"} [$__range]))"
        }]
      }
    ]
  })
}
```

**Benefits of Inline HCL:**

- **Dynamic datasource references**: Uses `grafana_data_source.loki.uid` for automatic UID resolution
- **Full version control**: Dashboard config is in HCL, part of your Terraform code
- **Infrastructure as Code**: Leverage Terraform variables, functions, and conditionals
- **Multi-environment support**: Easy to parameterize for different environments

### Dashboard Features

The Compliance Evidence Dashboard includes 8 panels:

1. **Total Evidence Records** - Stat panel showing total evidence count
2. **Policy Evaluation Results** - Pie chart of evaluation results
3. **Evaluation Results Summary** - Table view with color coding
4. **Policy Evaluation Over Time** - Time series graph with stacked bars
5. **Evidence by Policy Engine** - Donut chart breakdown
6. **Evidence by Policy Rule** - Donut chart breakdown
7. **Recent Evidence Records** - Table of recent evidence (last 100)
8. **Evidence Logs (Raw)** - Raw log viewer

### Drift Detection

To detect manual changes made in Grafana UI:

```bash
terraform plan
```

If you see changes, either:
- **Accept them**: Update `main.tf` with the changes and apply
- **Revert them**: Run `terraform apply` to restore Terraform's version
- **Refresh state**: Run `terraform refresh` to update state without applying

---

## Advanced Features

### 1. Managing Multiple Dashboards

Add more dashboard resources inline:

```hcl
resource "grafana_dashboard" "app_metrics" {
  overwrite = true

  config_json = jsonencode({
    title = "Application Metrics"
    uid   = "app-metrics"
    panels = [
      # Define panels here
    ]
  })
}

resource "grafana_dashboard" "infrastructure" {
  overwrite = true

  config_json = jsonencode({
    title = "Infrastructure Monitoring"
    uid   = "infrastructure"
    panels = [
      # Define panels here
    ]
  })
}
```

### 2. Folder Organization

Organize dashboards in folders:

```hcl
resource "grafana_folder" "compliance" {
  title = "Compliance Dashboards"
}

resource "grafana_dashboard" "compliance_evidence" {
  folder    = grafana_folder.compliance.id
  overwrite = true

  config_json = jsonencode({
    title = "Compliance Evidence"
    uid   = "compliance-evidence"
    panels = [
      # Panel definitions
    ]
  })
}
```

### 3. Dynamic Dashboards with Variables

Create dynamic configurations using Terraform features:

```hcl
locals {
  metrics = [
    "cpu_usage",
    "memory_usage",
    "disk_usage"
  ]
}

resource "grafana_dashboard" "monitoring" {
  overwrite = true

  config_json = jsonencode({
    title = "System Monitoring"
    uid   = "system-monitoring"

    panels = [
      for idx, metric in local.metrics : {
        id    = idx + 1
        title = upper(replace(metric, "_", " "))
        type  = "timeseries"
        gridPos = {
          x = (idx % 3) * 8
          y = floor(idx / 3) * 8
          w = 8
          h = 8
        }
        datasource = {
          type = "prometheus"
          uid  = grafana_data_source.prometheus.uid
        }
        targets = [{
          expr  = "rate(${metric}[5m])"
          refId = "A"
        }]
      }
    ]
  })
}
```

### 4. Environment-Specific Dashboards

```hcl
# variables.tf
variable "environment" {
  type = string
}

# main.tf
resource "grafana_dashboard" "app" {
  overwrite = true

  config_json = jsonencode({
    title = "Application Dashboard (${upper(var.environment)})"
    uid   = "app-${var.environment}"
    tags  = ["app", var.environment]

    panels = [
      {
        id    = 1
        title = "Requests (${var.environment})"
        type  = "graph"
        targets = [{
          expr = "rate(http_requests{env=\"${var.environment}\"}[5m])"
        }]
      }
    ]
  })
}
```

Usage:
```bash
# Development
terraform apply -var="environment=dev"

# Production
terraform apply -var="environment=prod"
```

### 5. Dynamic Datasource References

One of the biggest benefits of inline HCL dashboards:

```hcl
# Define datasource
resource "grafana_data_source" "loki" {
  type = "loki"
  name = "Loki"
  url  = var.loki_url
}

# Use in dashboard - automatically gets the correct UID!
resource "grafana_dashboard" "app" {
  overwrite = true

  config_json = jsonencode({
    title = "App Dashboard"
    panels = [
      {
        datasource = {
          type = "loki"
          uid  = grafana_data_source.loki.uid  # Dynamic!
        }
        targets = [{
          expr = "{app=\"myapp\"}"
        }]
      }
    ]
  })
}
```

If you recreate the datasource, the dashboard automatically gets the new UID!

---

## CI/CD Integration

### GitHub Actions Example

```yaml
# .github/workflows/deploy-dashboards.yml
name: Deploy Grafana Dashboards

on:
  push:
    branches: [main]
    paths:
      - 'hack/demo/terraform/*.tf'

jobs:
  terraform:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2

      - name: Terraform Init
        run: terraform init
        working-directory: hack/demo/terraform

      - name: Terraform Plan
        run: terraform plan
        working-directory: hack/demo/terraform
        env:
          TF_VAR_grafana_url: ${{ secrets.GRAFANA_URL }}
          TF_VAR_grafana_auth: ${{ secrets.GRAFANA_API_KEY }}
          TF_VAR_loki_url: ${{ vars.LOKI_URL }}

      - name: Terraform Apply
        run: terraform apply -auto-approve
        working-directory: hack/demo/terraform
        env:
          TF_VAR_grafana_url: ${{ secrets.GRAFANA_URL }}
          TF_VAR_grafana_auth: ${{ secrets.GRAFANA_API_KEY }}
          TF_VAR_loki_url: ${{ vars.LOKI_URL }}
```

### Required Secrets

Add these to your repository:
- `GRAFANA_URL`: Grafana server URL (e.g., https://grafana.example.com)
- `GRAFANA_API_KEY`: Grafana API key or admin:password
- `LOKI_URL` (as variable): Loki server URL

### GitLab CI Example

```yaml
# .gitlab-ci.yml
stages:
  - plan
  - deploy

terraform-plan:
  stage: plan
  image: hashicorp/terraform:latest
  script:
    - cd hack/demo/terraform
    - terraform init
    - terraform plan
  only:
    changes:
      - hack/demo/terraform/*.tf

terraform-apply:
  stage: deploy
  image: hashicorp/terraform:latest
  script:
    - cd hack/demo/terraform
    - terraform init
    - terraform apply -auto-approve
  only:
    - main
  when: manual
```

---

## Troubleshooting

### Authentication Issues

**Error: Authentication failed**

```bash
# Test Grafana connection
curl -u admin:admin http://localhost:3000/api/health

# Verify credentials are correct
terraform plan -var="grafana_auth=admin:admin"

# Check environment variables
echo $TF_VAR_grafana_auth
```

### Dashboard Not Appearing

**Dashboard not visible in Grafana:**

```bash
# Check Terraform state
terraform show

# Verify dashboard was created
terraform state list

# Force recreation
terraform taint grafana_dashboard.compliance_evidence
terraform apply
```

### Dashboard Not Updating

**Changes not being applied:**

1. Verify `overwrite = true` is set in resource
2. Check for UID conflicts with existing dashboards
3. Ensure dashboard exists in Terraform state

```bash
# Check if dashboard is in state
terraform state show grafana_dashboard.compliance_evidence

# If not, import it
terraform import grafana_dashboard.compliance_evidence compliance-evidence
```

### Dashboard Already Exists

**Error: Dashboard with UID already exists:**

```bash
# Option 1: Import existing dashboard
terraform import grafana_dashboard.compliance_evidence compliance-evidence

# Option 2: Delete existing dashboard in Grafana UI and reapply
terraform apply
```

### State Issues

**State corrupted or out of sync:**

```bash
# Refresh state from Grafana
terraform refresh

# Remove from state (last resort)
terraform state rm grafana_dashboard.compliance_evidence

# Reimport
terraform import grafana_dashboard.compliance_evidence compliance-evidence
```

### Datasource UID Issues

**Error: Datasource UID not found:**

```bash
# Check datasource exists
terraform state show grafana_data_source.loki

# Verify datasource UID in Grafana UI
# Configuration → Data Sources → Click on Loki → Check UID in URL

# Recreate datasource if needed
terraform taint grafana_data_source.loki
terraform apply
```

### Debugging Terraform

Enable debug logging:

```bash
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform-debug.log
terraform apply
```

View API calls being made:

```bash
export TF_LOG=TRACE
terraform apply
```

---

## Migration Guide

### From Docker Compose Provisioning

If you previously used Docker Compose volume mounts for dashboard provisioning:

**Old approach (removed):**
```yaml
# compose.yaml
services:
  grafana:
    volumes:
      - ./hack/demo/grafana/dashboards.yaml:/etc/grafana/provisioning/dashboards/dashboards.yaml
      - ./hack/demo/grafana/dashboards:/var/lib/grafana/dashboards
```

**New approach:**
- Dashboards managed exclusively via Terraform
- Dashboard defined inline in HCL in `hack/demo/terraform/main.tf`
- Deploy with `terraform apply`
- Benefits: Dynamic datasource references, full IaC capabilities

### From JSON Files to Inline HCL

If you have existing dashboard JSON files:

1. **Read the JSON file**:
   ```bash
   cat dashboard.json
   ```

2. **Convert to HCL**:
   ```hcl
   resource "grafana_dashboard" "my_dashboard" {
     overwrite = true

     config_json = jsonencode({
       # Paste JSON content here (remove outer { "dashboard": {} } wrapper)
       title = "My Dashboard"
       uid   = "my-dashboard"
       panels = [
         # ... panels from JSON
       ]
     })
   }
   ```

3. **Update datasource references**:
   - Replace hardcoded UIDs like `"uid": "P8E80F9AEF21F6940"`
   - With dynamic references: `uid = grafana_data_source.loki.uid`

4. **Apply**:
   ```bash
   terraform apply
   ```

### From Manual Grafana Dashboards

To import existing Grafana dashboards into Terraform:

1. **Export dashboard JSON** from Grafana UI

2. **Convert to inline HCL** (see above)

3. **Import into Terraform state**:
   ```bash
   terraform import grafana_dashboard.my_dashboard <dashboard-uid>
   ```

4. **Verify**:
   ```bash
   terraform plan  # Should show no changes
   ```


---

## Comparison: Manual vs Terraform

| Aspect | Manual | Terraform (Inline HCL) |
|--------|--------|------------------------|
| **Creation** | Click through UI | `terraform apply` |
| **Updates** | Find and edit each dashboard | Edit main.tf, apply once |
| **Versioning** | Export JSON manually | Git tracks HCL code |
| **Collaboration** | Risk of conflicts | Code review process |
| **Multi-env** | Recreate in each env | `terraform apply` in each |
| **Automation** | Not possible | CI/CD integration |
| **Rollback** | Manual restore | `git revert` + apply |
| **Consistency** | Manual errors | Guaranteed consistency |
| **Datasources** | Hardcoded UIDs | Dynamic references |

---

## Common Workflows

### Development → Production

```bash
# 1. Create dashboard in dev
cd environments/dev
terraform apply

# 2. Test and verify
# Visit http://grafana-dev.example.com

# 3. Promote to production
cd ../prod
terraform apply  # Uses same .tf files
```

### Team Collaboration

```
Developer A          Git Repo          Developer B
    │                   │                   │
    │  1. Edit main.tf  │                   │
    │  ────────────────▶│                   │
    │                   │                   │
    │  2. Commit & Push │                   │
    │  ────────────────▶│                   │
    │                   │                   │
    │                   │  3. Pull          │
    │                   │◀──────────────────│
    │                   │                   │
    │                   │  4. Review PR     │
    │                   │                   │
    │                   │  5. Merge & Apply │
    │                   │  terraform apply  │
```

### Disaster Recovery

```bash
# Grafana server crashed? No problem!
cd hack/demo/terraform
terraform apply

# All dashboards recreated in minutes from code
```

---

## Additional Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [Grafana Terraform Provider](https://registry.terraform.io/providers/grafana/grafana/latest/docs)
- [Infrastructure as Code Concepts](https://www.terraform.io/intro)

---

## Summary

**Terraform** is a tool that lets you manage Grafana dashboards (and other infrastructure) through code instead of manual clicking.

### Key Concepts

1. **Infrastructure as Code**: Dashboards defined in HCL code
2. **Version Control**: Track all changes in Git
3. **Automated Deployment**: Deploy with `terraform apply`
4. **State Management**: Terraform tracks what exists
5. **Dynamic References**: No hardcoded datasource UIDs

### Basic Commands

```bash
terraform init     # Setup (first time)
terraform plan     # Preview changes
terraform apply    # Create/update dashboards
terraform destroy  # Delete everything (careful!)
```

### Inline HCL Approach

Instead of managing JSON files, you define dashboards directly in HCL code using `jsonencode()`:

```hcl
resource "grafana_dashboard" "my_dashboard" {
  overwrite = true

  config_json = jsonencode({
    title = "My Dashboard"
    panels = [
      {
        datasource = {
          uid = grafana_data_source.loki.uid  # Dynamic!
        }
      }
    ]
  })
}
```

**Benefits:**
- Dynamic references to datasources
- Terraform variables and functions
- Better code reviews and diffs
- Full Infrastructure as Code capabilities

---

*Last updated: 2024*
