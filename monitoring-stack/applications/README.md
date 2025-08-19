# Microservices Application

## Overview
Complete microservices application with React frontend, Java Spring Boot backend, MySQL database, and Redis caching.

## Architecture
```
Frontend (React) → Backend (Spring Boot) → Database (MySQL)
                                      ↓
                                 Cache (Redis)
```

## Components

### Frontend
- **Technology**: React 18
- **Port**: 80
- **Features**: Dashboard with metrics display, user management
- **Monitoring**: Prometheus metrics via nginx

### Backend  
- **Technology**: Java 17 + Spring Boot 3
- **Port**: 8080
- **Features**: REST API, JPA, Redis caching, Prometheus metrics
- **Endpoints**: `/api/users`, `/api/metrics`, `/api/health`

### Database
- **MySQL 8.0**: Primary data storage
- **Redis 7**: Caching layer

## Local Development

### Prerequisites
- Node.js 18+
- Java 17+
- Maven 3.6+
- Docker & Docker Compose

### Run Locally
```bash
# Start databases
docker run -d --name mysql -e MYSQL_ROOT_PASSWORD=mysqlpassword -e MYSQL_DATABASE=monitoring -p 3306:3306 mysql:8.0
docker run -d --name redis -p 6379:6379 redis:7-alpine

# Start backend
cd applications/backend
mvn spring-boot:run

# Start frontend
cd applications/frontend
npm install
npm start
```

## Kubernetes Deployment

### Components
- **Frontend**: 3 replicas with nginx
- **Backend**: 3 replicas with health checks
- **MySQL**: 1 replica with persistent storage
- **Redis**: 1 replica with persistent storage

### Deploy to Kubernetes
```bash
kubectl apply -f applications/k8s-manifests/
```

## CI/CD Pipeline

### GitHub Actions Workflow
- **Triggers**: Changes in `applications/` directory
- **Path Detection**: Only builds changed components
- **Docker Build**: Multi-stage builds for optimization
- **Image Push**: To container registry
- **Manifest Update**: Automatic image tag updates
- **ArgoCD Sync**: Automatic deployment to cluster

### Required Secrets
```bash
REGISTRY_URL=your-registry-url
REGISTRY_USERNAME=your-username  
REGISTRY_PASSWORD=your-password
```

## Monitoring Integration

### Prometheus Metrics
- **Frontend**: nginx metrics on port 80
- **Backend**: Spring Boot Actuator metrics on `/actuator/prometheus`
- **Database**: MySQL exporter metrics
- **Cache**: Redis exporter metrics

### Health Checks
- **Backend**: `/api/health` endpoint
- **Kubernetes**: Liveness and readiness probes

## ArgoCD GitOps

### Application Sync
- **Repository**: Monitors `applications/k8s-manifests/`
- **Auto Sync**: Enabled with prune and self-heal
- **Retry Policy**: 5 attempts with exponential backoff

### Deployment Flow
1. Code changes pushed to repository
2. GitHub Actions builds and pushes images
3. Manifest files updated with new image tags
4. ArgoCD detects changes and syncs to cluster
5. Application deployed with zero downtime

## Scaling & Performance

### Horizontal Scaling
```bash
kubectl scale deployment frontend --replicas=5
kubectl scale deployment backend --replicas=5
```

### Resource Limits
- **Frontend**: 64Mi-128Mi memory, 50m-100m CPU
- **Backend**: 256Mi-512Mi memory, 100m-500m CPU
- **MySQL**: 256Mi-512Mi memory, 100m-500m CPU
- **Redis**: 64Mi-128Mi memory, 50m-100m CPU

## Troubleshooting

### Common Issues
1. **Database Connection**: Check MySQL service and credentials
2. **Cache Issues**: Verify Redis connectivity
3. **Image Pull**: Ensure registry credentials are correct
4. **Health Checks**: Check application logs for startup issues

### Debugging Commands
```bash
# Check pod status
kubectl get pods -n applications

# View logs
kubectl logs -f deployment/backend -n applications
kubectl logs -f deployment/frontend -n applications

# Check services
kubectl get svc -n applications

# Describe resources
kubectl describe deployment backend -n applications
```