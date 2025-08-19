# Troubleshooting Guide

## 🚨 Common Issues & Solutions

### Infrastructure Issues

#### 1. Terraform Deployment Failures
```bash
# Issue: Terraform state lock
Error: Error acquiring the state lock

# Solution: Force unlock (use carefully)
terraform force-unlock LOCK_ID

# Prevention: Use proper backend configuration
terraform {
  backend "s3" {
    bucket         = "terraform-state"
    key            = "infrastructure/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

#### 2. Kubernetes Cluster Access Issues
```bash
# Issue: Unable to connect to cluster
error: You must be logged in to the server (Unauthorized)

# Diagnosis
kubectl config current-context
kubectl config get-contexts

# Solution: Update kubeconfig
aws eks update-kubeconfig --region us-west-2 --name devops-cluster
az aks get-credentials --resource-group rg-monitoring --name aks-devops-cluster
gcloud container clusters get-credentials devops-cluster --zone us-central1

# Verify access
kubectl auth can-i get pods --all-namespaces
```

#### 3. ArgoCD Sync Issues
```bash
# Issue: Application stuck in "Progressing" state
# Diagnosis
argocd app get myapp --server argocd.company.com

# Common causes and solutions:
# 1. Resource conflicts
kubectl get events -n target-namespace --sort-by='.lastTimestamp'

# 2. RBAC issues
kubectl auth can-i create deployments --as=system:serviceaccount:argocd:argocd-application-controller -n target-namespace

# 3. Image pull issues
kubectl describe pod failing-pod -n target-namespace

# 4. Force refresh and sync
argocd app sync myapp --force --server argocd.company.com
```

### Monitoring Issues

#### 1. Prometheus Not Scraping Targets
```bash
# Issue: Targets showing as "DOWN" in Prometheus
# Diagnosis
curl http://prometheus:9090/api/v1/targets

# Common causes:
# 1. Service discovery issues
kubectl get servicemonitor -n monitoring
kubectl describe servicemonitor myapp -n monitoring

# 2. Network connectivity
kubectl exec -it prometheus-pod -n monitoring -- wget -qO- http://myapp:8080/metrics

# 3. Incorrect annotations
kubectl get pods -o yaml | grep -A5 -B5 prometheus.io

# Solution: Fix ServiceMonitor
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: myapp
spec:
  selector:
    matchLabels:
      app: myapp
  endpoints:
  - port: metrics
    path: /metrics
    interval: 30s
```

#### 2. Grafana Dashboard Not Loading Data
```bash
# Issue: "No data" in Grafana panels
# Diagnosis steps:

# 1. Check data source connectivity
curl -H "Authorization: Bearer $GRAFANA_TOKEN" \
  http://grafana:3000/api/datasources/proxy/1/api/v1/query?query=up

# 2. Verify query syntax in Prometheus
curl "http://prometheus:9090/api/v1/query?query=up"

# 3. Check time range and refresh interval
# 4. Verify metric names and labels

# Common fixes:
# - Update data source URL
# - Fix query syntax
# - Adjust time range
# - Check metric retention
```

#### 3. Alerts Not Firing
```bash
# Issue: Expected alerts not triggering
# Diagnosis

# 1. Check alert rule syntax
curl http://prometheus:9090/api/v1/rules

# 2. Verify alert state
curl http://prometheus:9090/api/v1/alerts

# 3. Check Alertmanager configuration
curl http://alertmanager:9093/api/v1/status

# 4. Test alert routing
amtool config routes test --config.file=/etc/alertmanager/alertmanager.yml

# Common issues:
# - Incorrect query syntax
# - Wrong threshold values
# - Missing labels for routing
# - Alertmanager routing rules
```

#### 4. Log Collection Issues
```bash
# Issue: Logs not appearing in Loki
# Diagnosis

# 1. Check Fluent Bit status
kubectl logs -f daemonset/fluent-bit -n monitoring

# 2. Verify Loki connectivity
kubectl exec -it fluent-bit-pod -n monitoring -- \
  curl -X POST "http://loki:3100/loki/api/v1/push" \
  -H "Content-Type: application/json" \
  -d '{"streams": [{"stream": {"job": "test"}, "values": [["1640995200000000000", "test message"]]}]}'

# 3. Check log parsing
kubectl logs fluent-bit-pod -n monitoring | grep ERROR

# Common fixes:
# - Fix Fluent Bit configuration
# - Update log parsing rules
# - Check Loki storage
# - Verify network policies
```

### Application Issues

#### 1. Pod Startup Failures
```bash
# Issue: Pods failing to start
# Diagnosis
kubectl get pods -n applications
kubectl describe pod failing-pod -n applications
kubectl logs failing-pod -n applications --previous

# Common causes and solutions:

# 1. Image pull errors
# Solution: Check image registry credentials
kubectl get secret regcred -o yaml

# 2. Resource constraints
# Solution: Adjust resource requests/limits
resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "500m"

# 3. Configuration errors
# Solution: Validate ConfigMaps and Secrets
kubectl get configmap myapp-config -o yaml
kubectl get secret myapp-secret -o yaml

# 4. Health check failures
# Solution: Fix health check endpoints
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10
```

#### 2. Service Discovery Issues
```bash
# Issue: Services can't communicate
# Diagnosis
kubectl get services -n applications
kubectl get endpoints myapp -n applications

# Test connectivity
kubectl run test-pod --image=busybox --rm -it -- /bin/sh
# Inside pod:
nslookup myapp.applications.svc.cluster.local
wget -qO- http://myapp.applications.svc.cluster.local:8080/health

# Common causes:
# 1. Incorrect service selector
# 2. Network policies blocking traffic
# 3. DNS resolution issues
# 4. Port configuration mismatch

# Solution: Fix service configuration
apiVersion: v1
kind: Service
metadata:
  name: myapp
spec:
  selector:
    app: myapp  # Must match pod labels
  ports:
  - port: 8080
    targetPort: 8080
```

#### 3. Database Connection Issues
```bash
# Issue: Application can't connect to database
# Diagnosis

# 1. Check database pod status
kubectl get pods -l app=mysql -n applications
kubectl logs mysql-pod -n applications

# 2. Test database connectivity
kubectl exec -it myapp-pod -n applications -- \
  mysql -h mysql-service -u root -p -e "SELECT 1"

# 3. Verify credentials
kubectl get secret mysql-secret -o yaml | base64 -d

# Common solutions:
# - Fix database credentials
# - Update connection strings
# - Check network policies
# - Verify database initialization
```

### CI/CD Issues

#### 1. GitHub Actions Failures
```bash
# Issue: Pipeline failing at specific steps
# Diagnosis steps:

# 1. Check workflow logs in GitHub Actions UI
# 2. Verify secrets configuration
# 3. Test locally with act (if possible)

# Common issues:

# Docker build failures
# Solution: Check Dockerfile and build context
docker build -t myapp .
docker run --rm myapp

# Registry push failures  
# Solution: Verify registry credentials
echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin

# Kubernetes deployment failures
# Solution: Validate manifests
kubeval k8s/*.yaml
kubectl apply --dry-run=client -f k8s/
```

#### 2. ArgoCD Application Sync Failures
```bash
# Issue: ArgoCD can't sync application
# Diagnosis

# 1. Check application status
argocd app get myapp

# 2. View sync operation details
argocd app sync myapp --dry-run

# 3. Check repository access
argocd repo get https://github.com/company/myapp

# Common solutions:
# - Update repository credentials
# - Fix manifest syntax errors
# - Resolve resource conflicts
# - Update RBAC permissions
```

### Performance Issues

#### 1. High Resource Usage
```bash
# Issue: Pods consuming too much CPU/Memory
# Diagnosis

# 1. Check resource usage
kubectl top pods -n applications
kubectl top nodes

# 2. Analyze metrics in Grafana
# - CPU usage over time
# - Memory usage patterns
# - Network I/O

# 3. Check for resource limits
kubectl describe pod high-usage-pod -n applications

# Solutions:
# - Optimize application code
# - Adjust resource limits
# - Implement horizontal scaling
# - Add resource quotas
```

#### 2. Slow Application Response
```bash
# Issue: Application responding slowly
# Diagnosis

# 1. Check application metrics
curl http://myapp:8080/actuator/metrics

# 2. Analyze traces in Grafana/Jaeger
# 3. Check database performance
# 4. Review network latency

# Common solutions:
# - Optimize database queries
# - Add caching layer
# - Scale application horizontally
# - Optimize container resources
```

## 🔧 Diagnostic Tools & Commands

### Essential Kubernetes Commands
```bash
# Pod diagnostics
kubectl get pods -o wide --all-namespaces
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> --previous
kubectl exec -it <pod-name> -n <namespace> -- /bin/sh

# Service diagnostics
kubectl get svc -o wide --all-namespaces
kubectl get endpoints <service-name> -n <namespace>
kubectl port-forward svc/<service-name> 8080:80 -n <namespace>

# Resource diagnostics
kubectl top nodes
kubectl top pods --all-namespaces
kubectl describe node <node-name>

# Event diagnostics
kubectl get events --sort-by='.lastTimestamp' -n <namespace>
kubectl get events --field-selector type=Warning --all-namespaces

# Network diagnostics
kubectl get networkpolicies --all-namespaces
kubectl describe networkpolicy <policy-name> -n <namespace>
```

### Monitoring Diagnostics
```bash
# Prometheus queries for troubleshooting
# High CPU usage
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# High memory usage
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Pod restart count
increase(kube_pod_container_status_restarts_total[1h])

# Service error rate
rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m])

# Grafana API for diagnostics
curl -H "Authorization: Bearer $GRAFANA_TOKEN" \
  "http://grafana:3000/api/datasources"

curl -H "Authorization: Bearer $GRAFANA_TOKEN" \
  "http://grafana:3000/api/search?query=&starred=false"
```

### Log Analysis
```bash
# Loki queries for troubleshooting
# Error logs
{namespace="applications"} |= "ERROR"

# Specific service logs
{namespace="applications", app="myapp"} | json | level="ERROR"

# Log volume by service
sum by (app) (count_over_time({namespace="applications"}[1h]))

# LogQL for pattern detection
{namespace="applications"} | pattern "<timestamp> <level> <message>"
```

## 🚨 Emergency Procedures

### Service Outage Response
```bash
# 1. Immediate Assessment (0-5 minutes)
# Check service status
kubectl get pods -l app=myapp -n applications
curl -f http://myapp.company.com/health

# Check recent deployments
argocd app history myapp
kubectl rollout history deployment/myapp -n applications

# 2. Quick Mitigation (5-15 minutes)
# Rollback if recent deployment
kubectl rollout undo deployment/myapp -n applications
argocd app rollback myapp

# Scale up if capacity issue
kubectl scale deployment myapp --replicas=10 -n applications

# 3. Communication (Parallel)
# Update status page
curl -X POST "https://api.statuspage.io/v1/pages/PAGE_ID/incidents" \
  -H "Authorization: OAuth $STATUSPAGE_TOKEN" \
  -d '{"incident": {"name": "Service Degradation", "status": "investigating"}}'

# Notify stakeholders
curl -X POST "$SLACK_WEBHOOK" \
  -d '{"text": "🚨 Service outage detected for myapp. Investigating..."}'
```

### Data Recovery Procedures
```bash
# Database recovery
# 1. Stop application traffic
kubectl scale deployment myapp --replicas=0 -n applications

# 2. Restore from backup
kubectl exec -it mysql-pod -n applications -- \
  mysql -u root -p mydb < /backup/mydb-backup.sql

# 3. Verify data integrity
kubectl exec -it mysql-pod -n applications -- \
  mysql -u root -p -e "SELECT COUNT(*) FROM users;"

# 4. Restart application
kubectl scale deployment myapp --replicas=3 -n applications
```

### Security Incident Response
```bash
# 1. Immediate containment
# Isolate affected pods
kubectl label pod suspicious-pod quarantine=true -n applications
kubectl patch networkpolicy default-deny -n applications --type='merge' \
  -p='{"spec":{"podSelector":{"matchLabels":{"quarantine":"true"}}}}'

# 2. Evidence collection
kubectl logs suspicious-pod -n applications > incident-logs.txt
kubectl describe pod suspicious-pod -n applications > incident-details.txt

# 3. System hardening
# Rotate secrets
kubectl delete secret app-secrets -n applications
kubectl create secret generic app-secrets --from-literal=password=new-password

# Update images
kubectl set image deployment/myapp myapp=myapp:patched-version -n applications
```

## 📞 Escalation Matrix

### Incident Severity Levels
```yaml
P0 - Critical:
  description: "Complete service outage affecting all users"
  response_time: "15 minutes"
  escalation: "Immediate to on-call engineer and management"
  
P1 - High:
  description: "Significant service degradation affecting most users"
  response_time: "30 minutes"
  escalation: "On-call engineer, escalate to team lead if not resolved in 1 hour"
  
P2 - Medium:
  description: "Partial service degradation affecting some users"
  response_time: "2 hours"
  escalation: "Assigned to team during business hours"
  
P3 - Low:
  description: "Minor issues with workarounds available"
  response_time: "24 hours"
  escalation: "Standard ticket queue"
```

### Contact Information
```yaml
Teams:
  DevOps:
    primary: "devops-oncall@company.com"
    slack: "#devops-alerts"
    pagerduty: "DEVOPS_ESCALATION_POLICY"
    
  Platform:
    primary: "platform-team@company.com"
    slack: "#platform-alerts"
    
  Security:
    primary: "security-team@company.com"
    slack: "#security-incidents"
    
  Management:
    engineering_manager: "em@company.com"
    director: "director@company.com"
```

This troubleshooting guide provides **systematic approaches** to diagnose and resolve common issues in your DevOps environment!