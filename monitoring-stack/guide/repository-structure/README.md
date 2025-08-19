# Repository Structure & Organization

## 🏢 XYZ Organization GitHub Structure

### Main DevOps Repository: `devops-platform`
```
devops-platform/
├── .github/
│   └── workflows/
│       ├── infrastructure-deploy.yml    # Infrastructure CI/CD
│       ├── monitoring-deploy.yml        # Monitoring stack CI/CD
│       ├── app-onboarding.yml          # New app onboarding
│       └── security-scan.yml           # Security scanning
├── infrastructure/
│   ├── aws/                            # AWS Terraform code
│   ├── azure/                          # Azure Terraform code
│   ├── gcp/                            # GCP Terraform code
│   └── scripts/                        # Deployment scripts
├── monitoring/
│   ├── alerts/                         # Prometheus alert rules
│   ├── dashboards/                     # Grafana dashboards
│   ├── charts/                         # Helm charts
│   └── exporters/                      # Custom exporters
├── argocd/
│   ├── applications/                   # ArgoCD app definitions
│   ├── projects/                       # ArgoCD projects
│   └── repositories/                   # Repository configurations
├── ci-cd/
│   ├── templates/                      # Reusable workflow templates
│   ├── policies/                       # Security and compliance policies
│   └── scripts/                        # CI/CD helper scripts
├── automation/
│   ├── onboarding/                     # App onboarding automation
│   ├── backup/                         # Backup automation
│   └── maintenance/                    # Maintenance scripts
├── docs/
│   ├── runbooks/                       # Operational runbooks
│   ├── architecture/                   # Architecture diagrams
│   └── guides/                         # How-to guides
└── configs/
    ├── secrets/                        # Secret templates (no actual secrets)
    ├── rbac/                          # RBAC configurations
    └── policies/                       # OPA/Gatekeeper policies
```

### Application Repositories Structure
```
app-{name}/
├── .github/
│   └── workflows/
│       ├── ci.yml                      # Build and test
│       ├── cd.yml                      # Deploy to staging/prod
│       └── security.yml               # Security scanning
├── src/                                # Application source code
├── k8s/
│   ├── base/                          # Base Kubernetes manifests
│   ├── overlays/
│   │   ├── staging/                   # Staging environment
│   │   └── production/                # Production environment
│   └── monitoring/                    # App-specific monitoring
├── docker/
│   ├── Dockerfile                     # Application container
│   └── docker-compose.yml            # Local development
├── charts/                            # Helm chart (if using Helm)
├── tests/                             # Application tests
└── docs/                              # Application documentation
```

## 🔧 Repository Management Strategy

### 1. DevOps Repository (`devops-platform`)
**Purpose**: Central hub for all infrastructure and DevOps operations

**Access Control**:
- **Admin**: DevOps team only
- **Write**: Senior developers (for monitoring configs)
- **Read**: All developers (for documentation)

**Branch Strategy**:
```
main                    # Production deployments
├── develop            # Development/staging
├── feature/*          # Feature branches
└── hotfix/*           # Emergency fixes
```

**Workflow**:
1. All infrastructure changes go through PR review
2. Automated testing on every PR
3. Staging deployment on develop branch
4. Production deployment on main branch merge

### 2. Application Repositories
**Purpose**: Individual application code and configurations

**Access Control**:
- **Admin**: Application team leads
- **Write**: Application developers
- **Read**: DevOps team, other developers

**Integration with DevOps**:
- Uses templates from `devops-platform/ci-cd/templates/`
- Monitoring configs synced to `devops-platform/monitoring/`
- ArgoCD applications auto-generated

## 📋 Repository Templates

### DevOps Repository Template
```bash
# Create new DevOps repository
gh repo create xyz-org/devops-platform --template xyz-org/devops-template --public

# Clone and customize
git clone https://github.com/xyz-org/devops-platform
cd devops-platform

# Initialize with organization-specific configs
./scripts/init-organization.sh --org xyz-org --cloud aws
```

### Application Repository Template
```bash
# Create new application repository
gh repo create xyz-org/app-newservice --template xyz-org/app-template --public

# Auto-onboard to DevOps platform
curl -X POST https://api.github.com/repos/xyz-org/devops-platform/dispatches \
  -H "Authorization: token $GITHUB_TOKEN" \
  -d '{"event_type": "onboard-app", "client_payload": {"repo": "app-newservice", "type": "microservice"}}'
```

## 🔐 Security & Access Management

### GitHub Organization Settings
```yaml
# .github/settings.yml
repository:
  default_branch: main
  allow_squash_merge: true
  allow_merge_commit: false
  allow_rebase_merge: true
  delete_branch_on_merge: true

security:
  require_signed_commits: true
  require_status_checks: true
  enforce_admins: true
  required_reviews: 2
  dismiss_stale_reviews: true

secrets:
  # Organization-level secrets
  - AWS_ACCESS_KEY_ID
  - AWS_SECRET_ACCESS_KEY
  - AZURE_CREDENTIALS
  - GCP_SA_KEY
  - DOCKER_REGISTRY_URL
  - DOCKER_REGISTRY_USERNAME
  - DOCKER_REGISTRY_PASSWORD
  - SLACK_WEBHOOK_URL
  - ARGOCD_SERVER
  - ARGOCD_TOKEN
```

### Team Structure
```yaml
teams:
  devops-core:
    members: [devops-lead, devops-engineer-1, devops-engineer-2]
    permissions: admin
    repositories: [devops-platform]
  
  developers:
    members: [dev-1, dev-2, dev-3]
    permissions: write
    repositories: [app-*]
  
  security:
    members: [security-lead, security-engineer]
    permissions: read
    repositories: [devops-platform, app-*]
```

## 🚀 Repository Automation

### Auto-Repository Creation
```yaml
# .github/workflows/create-repository.yml
name: Create New Repository
on:
  repository_dispatch:
    types: [create-repo]

jobs:
  create:
    runs-on: ubuntu-latest
    steps:
      - name: Create Repository
        run: |
          gh repo create ${{ github.event.client_payload.name }} \
            --template xyz-org/app-template \
            --${{ github.event.client_payload.visibility }}
      
      - name: Setup Repository
        run: |
          # Clone and customize
          git clone https://github.com/xyz-org/${{ github.event.client_payload.name }}
          cd ${{ github.event.client_payload.name }}
          
          # Replace template variables
          sed -i 's/{{APP_NAME}}/${{ github.event.client_payload.name }}/g' **/*.yml
          
          # Commit changes
          git add .
          git commit -m "Initialize repository from template"
          git push
```

### Auto-Onboarding Workflow
```yaml
# .github/workflows/onboard-application.yml
name: Onboard New Application
on:
  repository_dispatch:
    types: [onboard-app]

jobs:
  onboard:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Generate ArgoCD Application
        run: |
          APP_NAME=${{ github.event.client_payload.repo }}
          
          # Create ArgoCD application
          envsubst < templates/argocd-app.yaml > argocd/applications/${APP_NAME}.yaml
          
          # Create monitoring configuration
          envsubst < templates/monitoring-config.yaml > monitoring/apps/${APP_NAME}.yaml
          
          # Create PR
          git checkout -b onboard/${APP_NAME}
          git add .
          git commit -m "Onboard application: ${APP_NAME}"
          git push origin onboard/${APP_NAME}
          
          gh pr create --title "Onboard ${APP_NAME}" --body "Auto-generated onboarding PR"
```

## 📊 Repository Metrics & Monitoring

### Repository Health Dashboard
```yaml
# monitoring/dashboards/repository-health.json
{
  "dashboard": {
    "title": "Repository Health",
    "panels": [
      {
        "title": "Commit Frequency",
        "type": "graph",
        "targets": [
          {
            "expr": "github_commits_total",
            "legendFormat": "{{repository}}"
          }
        ]
      },
      {
        "title": "PR Merge Time",
        "type": "stat",
        "targets": [
          {
            "expr": "avg(github_pr_merge_time_seconds)",
            "legendFormat": "Average Merge Time"
          }
        ]
      },
      {
        "title": "Security Vulnerabilities",
        "type": "table",
        "targets": [
          {
            "expr": "github_security_alerts_total",
            "legendFormat": "{{repository}} - {{severity}}"
          }
        ]
      }
    ]
  }
}
```

### Repository Compliance Checks
```bash
#!/bin/bash
# scripts/check-repository-compliance.sh

REPOS=$(gh repo list xyz-org --limit 100 --json name -q '.[].name')

for repo in $REPOS; do
  echo "Checking compliance for $repo..."
  
  # Check branch protection
  gh api repos/xyz-org/$repo/branches/main/protection || echo "❌ No branch protection"
  
  # Check required status checks
  gh api repos/xyz-org/$repo/branches/main/protection/required_status_checks || echo "❌ No status checks"
  
  # Check security scanning
  gh api repos/xyz-org/$repo/code-scanning/alerts || echo "❌ No code scanning"
  
  # Check secrets scanning
  gh api repos/xyz-org/$repo/secret-scanning/alerts || echo "❌ No secret scanning"
done
```

## 🔄 Migration Strategy

### Existing Applications Migration
```bash
#!/bin/bash
# scripts/migrate-existing-apps.sh

# List of existing repositories
EXISTING_APPS=(
  "legacy-frontend"
  "legacy-backend" 
  "legacy-api"
)

for app in "${EXISTING_APPS[@]}"; do
  echo "Migrating $app..."
  
  # Clone existing repository
  git clone https://github.com/xyz-org/$app
  cd $app
  
  # Add DevOps structure
  mkdir -p .github/workflows k8s/base k8s/overlays/staging k8s/overlays/production
  
  # Copy templates
  cp ../devops-platform/ci-cd/templates/app-ci.yml .github/workflows/ci.yml
  cp ../devops-platform/ci-cd/templates/app-cd.yml .github/workflows/cd.yml
  
  # Generate Kubernetes manifests
  ../devops-platform/scripts/generate-k8s-manifests.sh --app $app --type microservice
  
  # Commit changes
  git add .
  git commit -m "Add DevOps automation structure"
  git push
  
  # Trigger onboarding
  gh workflow run onboard-application.yml -f app_name=$app
  
  cd ..
done
```

This repository structure provides a **scalable, secure, and automated** foundation for managing all DevOps operations in your organization!