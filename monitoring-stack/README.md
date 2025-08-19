# Monitoring Stack - Two Cluster Setup

## Overview
Monitoring stack for two Kubernetes clusters:
- **devops-cluster**: Infrastructure and monitoring services
- **application-cluster**: Application workloads

## Architecture
- **Grafana**: Dashboards and visualization
- **Mimir**: Metrics storage
- **Loki**: Log aggregation  
- **Tempo**: Distributed tracing
- **Alertmanager**: Alert routing
- **GitHub Actions**: CI/CD pipeline
- **ArgoCD**: GitOps deployment

## Clusters
| Cluster | Purpose | Tenant ID |
|---------|---------|-----------|
| devops-cluster | Infrastructure monitoring | _devops |
| application-cluster | Application monitoring | _apps |

## Alert Routing
| Cluster | Type | Severity | Slack Channel |
|---------|------|----------|---------------|
| DevOps | Infra | Warning | devops-infra-warning |
| DevOps | Infra | Critical | devops-infra-critical |
| DevOps | Service | Warning | devops-service-warning |
| DevOps | Service | Critical | devops-service-critical |
| Application | Infra | Warning | app-infra-warning |
| Application | Infra | Critical | app-infra-critical |
| Application | Service | Warning | app-service-warning |
| Application | Service | Critical | app-service-critical |