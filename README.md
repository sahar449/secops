# SecOps Kubernetes Deployment

A secure Kubernetes deployment pipeline with Cosign image signing and Kyverno policy enforcement.

## Overview

This project demonstrates a complete secure DevOps pipeline that includes:
- Docker image building and signing with Cosign
- Kubernetes deployment with security policies
- Kyverno policy validation
- Jenkins CI/CD automation

## Architecture

```
┌─────────────┐    ┌──────────────┐    ┌─────────────────┐
│   Jenkins   │───▶│ Docker Build │───▶│ Cosign Signing  │
└─────────────┘    └──────────────┘    └─────────────────┘
       │                                        │
       ▼                                        ▼
┌─────────────┐    ┌──────────────┐    ┌─────────────────┐
│  Kyverno    │◀───│ Kubernetes   │◀───│ Registry Push   │
│ Validation  │    │ Deployment   │    └─────────────────┘
└─────────────┘    └──────────────┘
```

## Prerequisites

- Kubernetes cluster (v1.20+)
- Jenkins with Docker and kubectl plugins
- Cosign CLI installed
- Kyverno installed in the cluster
- Docker Hub account

## Installation

### 1. Install Kyverno
```bash
kubectl create -f https://github.com/kyverno/kyverno/releases/download/v1.10.0/install.yaml
```

### 2. Apply Kyverno Policies
```bash
kubectl apply -f kyverno-policy.yaml
```

### 3. Deploy Application
```bash
kubectl apply -f k8s/
```

## Security Features

### Kyverno Policy Enforcement
The included Kyverno policy enforces:
- **No Privileged Containers**: Prevents containers from running in privileged mode
- **Non-Root Execution**: Ensures all containers run as non-root users
- **Resource Limits**: Requires CPU and memory limits for all containers

### Cosign Image Signing
All container images are signed using Cosign to ensure:
- Image integrity verification
- Supply chain security
- Tamper detection

### Secure Deployment Configuration
The Kubernetes manifests include:
- Security contexts with non-root users
- Read-only root filesystems
- Dropped capabilities
- Resource limits and requests

## Jenkins Pipeline

The Jenkins pipeline automates:
1. **Source Code Checkout**
2. **Docker Image Build**
3. **Image Registry Push**
4. **Cosign Image Signing**
5. **Kyverno Policy Validation**
6. **Kubernetes Deployment**
7. **Deployment Verification**

## Configuration

### Required Jenkins Credentials
- `kubeconfig`: Kubernetes cluster configuration
- `cosign-password`: Cosign private key password
- `docker-hub`: Docker Hub username and password

### Environment Variables
```bash
DOCKER_REGISTRY=sahar449
IMAGE_NAME=secops
```

## Usage

### Manual Deployment
```bash
# Build and push image
docker build -t sahar449/secops:latest .
docker push sahar449/secops:latest

# Sign image
cosign sign --key jenkins.key sahar449/secops:latest

# Deploy to Kubernetes
kubectl apply -f k8s/
```

### Jenkins Deployment
1. Create a new Jenkins Pipeline job
2. Configure the repository URL
3. Set the Jenkinsfile path
4. Add required credentials
5. Run the pipeline

## Monitoring

### Check Deployment Status
```bash
kubectl get deployments
kubectl get pods -l app=nginx-app
kubectl get svc nginx-service
```

### Verify Kyverno Policies
```bash
kubectl get cpol
kubectl describe cpol require-pod-security
```

### Verify Image Signatures
```bash
cosign verify --key cosign.pub sahar449/secops:latest
```

## Troubleshooting

### Common Issues

1. **Kyverno Policy Violations**
   - Check resource limits are specified
   - Ensure securityContext is configured
   - Verify non-root user settings

2. **Cosign Signing Failures**
   - Verify private key permissions
   - Check password environment variable
   - Ensure Cosign CLI is installed

3. **Deployment Failures**
   - Check image pull secrets
   - Verify RBAC permissions
   - Review pod security policies

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
- Create an issue in the repository
- Check the troubleshooting section
- Review Kubernetes and Kyverno documentation