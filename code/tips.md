# Kubernetes Quick Tips & Commands

## Overview

Creating and editing YAML files manually can be challenging, especially in CLI environments. During Kubernetes exams or real-world scenarios, you might find it difficult to copy and paste YAML files from documentation to the terminal.

**Pro Tip:** Use `kubectl` imperative commands to generate YAML templates quickly, or even create resources directly without writing YAML files at all!

## Key Benefits

- ⚡ **Faster resource creation** - Skip manual YAML writing
- **Reduce errors** - Generated YAML is syntactically correct
- **Template generation** - Create base YAML files to customize
- **Exam efficiency** - Save time during certification exams

---

## Essential Reference

��� **Bookmark this page for quick reference:**
https://kubernetes.io/docs/reference/kubectl/conventions/

---

## Pod Commands

### Create a Pod

```bash
kubectl run nginx --image=nginx
```

### Generate Pod YAML (without creating)

```bash
kubectl run nginx --image=nginx --dry-run=client -o yaml
```

### Generate Pod YAML and save to file

```bash
kubectl run nginx --image=nginx --dry-run=client -o yaml > nginx-pod.yaml
```

---

## Deployment Commands

### Create a Deployment

```bash
kubectl create deployment nginx --image=nginx
```

### Generate Deployment YAML (without creating)

```bash
kubectl create deployment nginx --image=nginx --dry-run=client -o yaml
```

### Generate Deployment YAML and save to file

```bash
kubectl create deployment nginx --image=nginx --dry-run=client -o yaml > nginx-deployment.yaml
```

### Create Deployment with specific replica count (K8s 1.19+)

```bash
kubectl create deployment nginx --image=nginx --replicas=4 --dry-run=client -o yaml > nginx-deployment.yaml
```

---

## Workflow Examples

### Method 1: Generate and Customize

1. **Generate YAML template:**
   ```bash
   kubectl create deployment nginx --image=nginx --dry-run=client -o yaml > nginx-deployment.yaml
   ```

2. **Edit the file** (add replicas, resources, etc.)

3. **Apply the configuration:**
   ```bash
   kubectl apply -f nginx-deployment.yaml
   ```

### Method 2: Direct Creation with Options

```bash
# Create deployment with 4 replicas directly
kubectl create deployment nginx --image=nginx --replicas=4
```

---

## Additional Useful Commands

### Service Commands

```bash
# Create a ClusterIP service
kubectl create service clusterip nginx --tcp=80:80

# Create a NodePort service
kubectl create service nodeport nginx --tcp=80:80

# Expose a deployment
kubectl expose deployment nginx --port=80 --target-port=80
```

### ConfigMap and Secret Commands

```bash
# Create ConfigMap from literal values
kubectl create configmap app-config --from-literal=key1=value1 --from-literal=key2=value2

# Create ConfigMap from file
kubectl create configmap app-config --from-file=config.properties

# Create Secret from literal values
kubectl create secret generic app-secret --from-literal=username=admin --from-literal=password=secret123

# Create Secret from file
kubectl create secret generic app-secret --from-file=credentials.txt
```

### Job and CronJob Commands

```bash
# Create a Job
kubectl create job hello --image=busybox -- echo "Hello World"

# Create a CronJob
kubectl create cronjob hello --image=busybox --schedule="*/1 * * * *" -- echo "Hello World"
```

---

## Best Practices

1. **Use imperative commands** for quick resource creation
2. **Generate YAML templates** when you need customization
3. **Always use `--dry-run=client -o yaml`** to preview before creating
4. **Save generated YAML** for version control and future reference
5. **Combine approaches** - generate base template, then customize as needed
6. **Use meaningful names** for your resources
7. **Add labels and annotations** for better organization

---

## Quick Command Reference

| Task | Command |
|------|---------|
| Create Pod | `kubectl run <name> --image=<image>` |
| Create Deployment | `kubectl create deployment <name> --image=<image>` |
| Create Service | `kubectl create service <type> <name> --tcp=<port>:<target-port>` |
| Generate YAML | Add `--dry-run=client -o yaml` |
| Save to file | Add `> filename.yaml` |
| Set replicas | Add `--replicas=<count>` (deployments only) |
| Apply YAML | `kubectl apply -f <filename.yaml>` |
| Delete resource | `kubectl delete <resource-type> <name>` |

---

## Exam Tips

- ��� **Practice these commands** until they become second nature
- ��� **Use short aliases** like `k` for `kubectl` (if allowed)
- ⏱️ **Time-saving shortcuts** can make the difference in exams
- ��� **Focus on imperative commands** for simple tasks
- ��� **Use YAML generation** for complex configurations

> ��� **Practice Tip:** Try using these commands instead of manual YAML creation in your practice tests and exercises!

---

## Common Troubleshooting Commands

```bash
# Get detailed information about a resource
kubectl describe <resource-type> <name>

# View logs
kubectl logs <pod-name>

# Execute commands in a pod
kubectl exec -it <pod-name> -- /bin/bash

# Port forwarding
kubectl port-forward <pod-name> <local-port>:<pod-port>

# Get events
kubectl get events --sort-by=.metadata.creationTimestamp
```
