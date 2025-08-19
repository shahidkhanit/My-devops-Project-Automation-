# DevOps Best Practices & Standards

## 🎯 Core Principles

### 1. Infrastructure as Code (IaC)
- **Everything in Git**: All infrastructure defined in version-controlled code
- **Immutable Infrastructure**: Replace, don't modify
- **Environment Parity**: Identical environments across dev/staging/prod
- **Automated Testing**: Validate infrastructure changes before deployment

### 2. GitOps Methodology
- **Git as Single Source of Truth**: All changes via Git commits
- **Pull-based Deployments**: ArgoCD pulls changes automatically
- **Declarative Configuration**: Describe desired state, not steps
- **Continuous Reconciliation**: Automatic drift detection and correction

### 3. Security First
- **Least Privilege Access**: Minimal required permissions
- **Secrets Management**: Never store secrets in Git
- **Regular Security Scans**: Automated vulnerability detection
- **Compliance Monitoring**: Continuous policy enforcement

## 📋 Repository Standards

### Git Workflow Standards
```bash
# Branch Naming Convention
feature/JIRA-123-add-monitoring     # New features
bugfix/JIRA-456-fix-alert-routing   # Bug fixes
hotfix/JIRA-789-critical-security   # Emergency fixes
release/v1.2.0                      # Release branches

# Commit Message Format
type(scope): description

# Examples:
feat(monitoring): add Redis exporter
fix(alerts): correct threshold for CPU alerts
docs(readme): update installation guide
chore(deps): update Terraform to v1.5
```

### Code Review Standards
```yaml
# .github/CODEOWNERS
# Global owners
* @devops-team

# Infrastructure changes require security review
infrastructure/ @devops-team @security-team

# Monitoring changes require platform team review
monitoring/ @devops-team @platform-team

# Alert changes require on-call team review
alerts/ @devops-team @oncall-team
```

### Pull Request Template
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Infrastructure change
- [ ] Monitoring configuration
- [ ] Security update
- [ ] Documentation update

## Testing
- [ ] Terraform plan reviewed
- [ ] Monitoring alerts tested
- [ ] Security scan passed
- [ ] Documentation updated

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] Breaking changes documented
```

## 🏗️ Infrastructure Standards

### Terraform Best Practices
```hcl
# File Organization
terraform/
├── modules/
│   ├── vpc/
│   ├── eks/
│   └── monitoring/
├── environments/
│   ├── dev/
│   ├── staging/
│   └── prod/
└── shared/
    ├── variables.tf
    └── outputs.tf

# Variable Naming
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

# Resource Naming Convention
resource "aws_eks_cluster" "main" {
  name = "${var.project}-${var.environment}-cluster"
  
  tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
    Owner       = var.team
  }
}

# State Management
terraform {
  backend "s3" {
    bucket         = "company-terraform-state"
    key            = "infrastructure/${var.environment}/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

### Kubernetes Standards
```yaml
# Resource Naming Convention
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-deployment
  namespace: applications
  labels:
    app: frontend
    version: v1.0.0
    component: web
    part-of: ecommerce
    managed-by: argocd
  annotations:
    deployment.kubernetes.io/revision: "1"
    argocd.argoproj.io/sync-wave: "2"

# Resource Limits (Required)
spec:
  template:
    spec:
      containers:
      - name: frontend
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"

# Security Context (Required)
        securityContext:
          allowPrivilegeEscalation: false
          runAsNonRoot: true
          runAsUser: 1000
          capabilities:
            drop:
            - ALL
          readOnlyRootFilesystem: true

# Health Checks (Required)
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
```

### Helm Chart Standards
```yaml
# Chart.yaml
apiVersion: v2
name: microservice
description: Standard microservice Helm chart
type: application
version: 1.0.0
appVersion: "1.0.0"
keywords:
  - microservice
  - monitoring
maintainers:
  - name: DevOps Team
    email: devops@company.com

# values.yaml Structure
global:
  imageRegistry: ""
  environment: ""
  
image:
  repository: ""
  tag: ""
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: false
  className: "nginx"
  annotations: {}

resources:
  requests:
    memory: "64Mi"
    cpu: "50m"
  limits:
    memory: "128Mi"
    cpu: "100m"

monitoring:
  enabled: true
  serviceMonitor:
    enabled: true
    interval: 30s
```

## 📊 Monitoring Standards

### Metrics Standards
```yaml
# Metric Naming Convention
# Format: {namespace}_{subsystem}_{name}_{unit}
http_requests_total                    # Counter
http_request_duration_seconds         # Histogram
memory_usage_bytes                    # Gauge
database_connections_active           # Gauge

# Required Labels
- job: "service-name"
- instance: "pod-ip:port"
- environment: "prod|staging|dev"
- version: "v1.0.0"
- team: "backend|frontend|platform"

# Custom Business Metrics
business_orders_total{status="completed",region="us-west"}
business_revenue_dollars{product="premium",region="eu-central"}
business_users_active{tier="free",region="ap-southeast"}
```

### Alert Standards
```yaml
# Alert Naming Convention
groups:
- name: service.rules
  rules:
  - alert: ServiceHighErrorRate        # PascalCase
    expr: |
      (
        rate(http_requests_total{status=~"5.."}[5m]) /
        rate(http_requests_total[5m])
      ) > 0.05
    for: 5m                           # Appropriate duration
    labels:
      severity: warning               # info|warning|critical
      team: backend                   # Responsible team
      service: user-api              # Affected service
      runbook: "https://runbooks.company.com/high-error-rate"
    annotations:
      summary: "High error rate detected"
      description: "Error rate is {{ $value | humanizePercentage }} for {{ $labels.service }}"
      impact: "Users may experience service degradation"
      action: "Check application logs and recent deployments"

# Severity Guidelines
# critical: Immediate action required, affects users
# warning: Action required within business hours
# info: Informational, no immediate action needed
```

### Dashboard Standards
```json
{
  "dashboard": {
    "title": "Service Name - Overview",
    "tags": ["service", "team-name"],
    "timezone": "UTC",
    "refresh": "30s",
    
    "templating": {
      "list": [
        {
          "name": "environment",
          "type": "query",
          "query": "label_values(up, environment)"
        },
        {
          "name": "service",
          "type": "query", 
          "query": "label_values(up{environment=\"$environment\"}, job)"
        }
      ]
    },
    
    "panels": [
      {
        "title": "Request Rate",
        "type": "graph",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0},
        "targets": [
          {
            "expr": "sum(rate(http_requests_total{job=\"$service\",environment=\"$environment\"}[5m]))",
            "legendFormat": "Requests/sec"
          }
        ]
      }
    ]
  }
}
```

## 🔐 Security Standards

### Secrets Management
```yaml
# Never store secrets in Git
# Use external secret management

# Kubernetes Secrets
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
data:
  # Values are base64 encoded
  database-password: <base64-encoded-value>

# External Secrets Operator
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: vault-backend
spec:
  provider:
    vault:
      server: "https://vault.company.com"
      path: "secret"
      version: "v2"
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "demo"

# AWS Secrets Manager
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: app-secrets
spec:
  refreshInterval: 15s
  secretStoreRef:
    name: aws-secrets-manager
    kind: SecretStore
  target:
    name: app-secrets
    creationPolicy: Owner
  data:
  - secretKey: password
    remoteRef:
      key: prod/database
      property: password
```

### RBAC Standards
```yaml
# Service Account
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-service-account
  namespace: applications

# Role (Namespace-scoped)
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: applications
  name: app-role
rules:
- apiGroups: [""]
  resources: ["pods", "services"]
  verbs: ["get", "list", "watch"]

# ClusterRole (Cluster-scoped)
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: monitoring-reader
rules:
- apiGroups: [""]
  resources: ["nodes", "nodes/metrics", "services", "endpoints", "pods"]
  verbs: ["get", "list", "watch"]

# RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-binding
  namespace: applications
subjects:
- kind: ServiceAccount
  name: app-service-account
  namespace: applications
roleRef:
  kind: Role
  name: app-role
  apiGroup: rbac.authorization.k8s.io
```

### Network Policies
```yaml
# Default Deny All
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: applications
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress

# Allow Specific Communication
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-to-backend
  namespace: applications
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
```

## 🚀 CI/CD Standards

### Pipeline Standards
```yaml
# Required Stages
stages:
  - validate    # Syntax and format validation
  - test       # Unit and integration tests
  - security   # Security scanning
  - build      # Build artifacts
  - deploy     # Deploy to environments

# Required Checks
checks:
  - code_quality: sonarqube
  - security_scan: trivy
  - dependency_check: snyk
  - license_check: fossa
  - compliance: opa

# Environment Promotion
environments:
  development:
    auto_deploy: true
    approval: false
  staging:
    auto_deploy: true
    approval: false
  production:
    auto_deploy: false
    approval: true
    approvers: ["devops-team", "security-team"]
```

### Deployment Standards
```yaml
# Blue-Green Deployment
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 0
    maxSurge: 1

# Canary Deployment with Argo Rollouts
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: frontend-rollout
spec:
  replicas: 10
  strategy:
    canary:
      steps:
      - setWeight: 10
      - pause: {duration: 2m}
      - setWeight: 50
      - pause: {duration: 5m}
      - setWeight: 100
      analysis:
        templates:
        - templateName: success-rate
        args:
        - name: service-name
          value: frontend
```

## 📈 Performance Standards

### Resource Management
```yaml
# Resource Quotas per Namespace
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: applications
spec:
  hard:
    requests.cpu: "10"
    requests.memory: 20Gi
    limits.cpu: "20"
    limits.memory: 40Gi
    persistentvolumeclaims: "10"

# Limit Ranges
apiVersion: v1
kind: LimitRange
metadata:
  name: mem-limit-range
  namespace: applications
spec:
  limits:
  - default:
      memory: "512Mi"
      cpu: "500m"
    defaultRequest:
      memory: "256Mi"
      cpu: "100m"
    type: Container
```

### Horizontal Pod Autoscaling
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: frontend-hpa
  namespace: applications
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: frontend
  minReplicas: 3
  maxReplicas: 100
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

## 📚 Documentation Standards

### README Template
```markdown
# Service Name

## Overview
Brief description of the service

## Architecture
High-level architecture diagram

## Getting Started
### Prerequisites
### Installation
### Configuration

## API Documentation
Link to API docs (Swagger/OpenAPI)

## Monitoring
- Dashboards: [Link to Grafana]
- Alerts: [Link to alert definitions]
- Runbooks: [Link to operational runbooks]

## Development
### Local Development
### Testing
### Deployment

## Troubleshooting
Common issues and solutions

## Contributing
How to contribute to this service

## Support
Contact information for support
```

### Runbook Template
```markdown
# Alert: ServiceHighErrorRate

## Summary
High error rate detected for service

## Impact
- User Impact: Users may experience service errors
- Business Impact: Potential revenue loss
- SLA Impact: May breach 99.9% availability SLA

## Diagnosis
1. Check service health dashboard
2. Review recent deployments
3. Check application logs
4. Verify database connectivity

## Resolution
### Immediate Actions
1. Check if recent deployment caused issue
2. Rollback if necessary
3. Scale up service if needed

### Investigation
1. Analyze error patterns in logs
2. Check database performance
3. Review infrastructure metrics

## Prevention
- Improve testing coverage
- Add more comprehensive monitoring
- Implement circuit breakers

## Escalation
- L1: On-call engineer (15 minutes)
- L2: Service owner (30 minutes)  
- L3: Engineering manager (1 hour)
```

These best practices ensure **consistent, secure, and maintainable** DevOps operations across your entire organization!