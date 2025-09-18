# Kubernetes Imperative Commands Guide

## Overview

While declarative approaches using YAML definition files are the preferred method for production environments, imperative commands are invaluable for:
- Quick one-time tasks
- Generating YAML templates rapidly
- Troubleshooting and debugging
- Exam scenarios where speed is crucial

## Essential Command Options

Before diving into specific commands, understand these two powerful options:

### `--dry-run=client`
- **Purpose**: Test commands without creating actual resources
- **Benefit**: Validates command syntax and resource feasibility
- **Usage**: Append to any create command to simulate execution

### `-o yaml`
- **Purpose**: Output resource definitions in YAML format
- **Benefit**: Generate templates for further customization
- **Usage**: Combine with `--dry-run=client` for template generation

### Pro Tip: Template Generation Workflow
```bash
# Generate template → Save to file → Customize → Apply
kubectl create <resource> --dry-run=client -o yaml > resource-template.yaml
```

---

## Pod Operations

### Basic Pod Creation
```bash
# Create an NGINX pod immediately
kubectl run nginx --image=nginx
```

### Generate Pod YAML Template
```bash
# Generate pod manifest without creating the resource
kubectl run nginx --image=nginx --dry-run=client -o yaml
```

### Advanced Pod Options
```bash
# Pod with custom labels
kubectl run nginx --image=nginx --labels="app=web,tier=frontend"

# Pod with resource limits
kubectl run nginx --image=nginx --requests="cpu=100m,memory=128Mi" --limits="cpu=200m,memory=256Mi"

# Pod with environment variables
kubectl run nginx --image=nginx --env="ENV=production"
```

---

## Deployment Operations

### Basic Deployment Creation
```bash
# Create a deployment
kubectl create deployment nginx --image=nginx
```

### Generate Deployment YAML Template
```bash
# Generate deployment manifest without creating
kubectl create deployment nginx --image=nginx --dry-run=client -o yaml
```

### Deployment with Replicas
```bash
# Create deployment with specific replica count
kubectl create deployment nginx --image=nginx --replicas=4
```

### Scaling Deployments
```bash
# Scale existing deployment
kubectl scale deployment nginx --replicas=4

# Alternative: Edit deployment directly
kubectl edit deployment nginx
```

### Template Generation and Customization
```bash
# Generate template file for further customization
kubectl create deployment nginx --image=nginx --dry-run=client -o yaml > nginx-deployment.yaml

# Edit the file as needed, then apply
kubectl apply -f nginx-deployment.yaml
```

---

## Service Operations

### ClusterIP Service

#### Method 1: Using `kubectl expose` (Recommended)
```bash
# Expose pod with automatic label selection
kubectl expose pod redis --port=6379 --name=redis-service --dry-run=client -o yaml
```
**Advantages:**
- Automatically uses pod's labels as selectors
- Simple and intuitive syntax

#### Method 2: Using `kubectl create service`
```bash
# Create service with manual configuration
kubectl create service clusterip redis --tcp=6379:6379 --dry-run=client -o yaml
```
**Limitations:**
- Uses default selector `app=redis`
- Cannot specify custom selectors via command line
- Requires manual selector modification if pod labels differ

### NodePort Service

#### Method 1: Using `kubectl expose`
```bash
# Expose pod as NodePort (auto-assigned port)
kubectl expose pod nginx --type=NodePort --port=80 --name=nginx-service --dry-run=client -o yaml
```
**Limitations:**
- Cannot specify custom NodePort via command line
- Requires manual editing for specific port assignment

#### Method 2: Using `kubectl create service`
```bash
# Create NodePort service with specific port
kubectl create service nodeport nginx --tcp=80:80 --node-port=30080 --dry-run=client -o yaml
```
**Limitations:**
- Doesn't use pod labels as selectors
- Uses default selector pattern

### Service Creation Best Practices

1. **For ClusterIP services**: Use `kubectl expose` for simplicity
2. **For NodePort services**: 
   - Use `kubectl expose` + manual port editing, OR
   - Use `kubectl create service` + manual selector editing
3. **Always generate YAML first** for complex services:
   ```bash
   kubectl expose pod nginx --type=NodePort --port=80 --name=nginx-service --dry-run=client -o yaml > nginx-service.yaml
   # Edit nodePort field manually
   kubectl apply -f nginx-service.yaml
   ```

---

## Quick Reference Commands

### Pod Management
```bash
kubectl run <pod-name> --image=<image>                    # Create pod
kubectl get pods                                          # List pods
kubectl describe pod <pod-name>                           # Pod details
kubectl delete pod <pod-name>                             # Delete pod
kubectl logs <pod-name>                                   # View logs
```

### Deployment Management
```bash
kubectl create deployment <name> --image=<image>          # Create deployment
kubectl get deployments                                   # List deployments
kubectl scale deployment <name> --replicas=<count>       # Scale deployment
kubectl rollout status deployment <name>                 # Check rollout status
kubectl delete deployment <name>                         # Delete deployment
```

### Service Management
```bash
kubectl expose <resource> <name> --port=<port>           # Expose resource
kubectl get services                                      # List services
kubectl describe service <service-name>                  # Service details
kubectl delete service <service-name>                    # Delete service
```

---

## Troubleshooting Tips

1. **Command Validation**: Always test with `--dry-run=client` first
2. **YAML Generation**: Use `-o yaml` to understand resource structure
3. **Label Mismatches**: Check selectors when services don't connect to pods
4. **Port Conflicts**: Verify NodePort ranges (30000-32767)
5. **Resource Quotas**: Check namespace limits if creation fails

---

## Additional Resources

- [Official kubectl Command Reference](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands)
- [kubectl Conventions and Best Practices](https://kubernetes.io/docs/reference/kubectl/conventions/)
- [Kubernetes Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)