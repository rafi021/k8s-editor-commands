# Kubernetes Setup Scripts - Comprehensive Test Plan

## Executive Summary
This document outlines a comprehensive testing strategy for the Kubernetes master and worker node setup scripts intended for production deployment on Ubuntu 22.04 and 24.04.

## Critical Issues Found (MUST FIX)
⛔ **IMMEDIATE ACTION REQUIRED** - These issues will cause production failures:

1. **Invalid Kubernetes Version** 
   - Current: `K8S_VERSION_SHORT="1.34.1"` (doesn't exist)
   - Fix: Use `K8S_VERSION_SHORT="1.30.0"` or `1.29.0`
   - Impact: Scripts will fail during package installation

2. **Incorrect Shebang**
   - Current: `// ...existing code...` (appears to be corrupted)
   - Fix: Should be `#!/usr/bin/env bash`
   - Impact: Scripts won't execute properly

## Test Environment Requirements

### Hardware Requirements (Per Node)
- **Minimum**: 2 CPU cores, 2GB RAM, 20GB disk
- **Recommended**: 4 CPU cores, 4GB RAM, 50GB disk
- Network connectivity between nodes

### Software Requirements
- Ubuntu 22.04 LTS or Ubuntu 24.04 LTS
- Root access (sudo privileges)
- Internet connectivity for package downloads

## Pre-Test Preparation

### 1. Environment Setup
```bash
# Create test VMs or containers
# Ubuntu 22.04
# Ubuntu 24.04

# Ensure clean state
sudo apt update
sudo systemctl stop kubelet 2>/dev/null || true
sudo systemctl stop crio 2>/dev/null || true
```

### 2. Script Preparation
Before testing, fix the critical issues:

```bash
# Fix shebang in both scripts
sed -i '1s|.*|#!/usr/bin/env bash|' k8s_master_node.sh
sed -i '1s|.*|#!/usr/bin/env bash|' k8s_worker_node.sh

# Fix Kubernetes version
sed -i 's/K8S_VERSION_SHORT="1.34.1"/K8S_VERSION_SHORT="1.30.0"/' k8s_master_node.sh
sed -i 's/K8S_VERSION_SHORT="1.34.1"/K8S_VERSION_SHORT="1.30.0"/' k8s_worker_node.sh
```

## Test Scenarios

### Test 1: Static Analysis
**Objective**: Validate script syntax and structure
**Script**: `validate_scripts.py`

```bash
python validate_scripts.py
# Expected: All critical issues resolved
```

### Test 2: Ubuntu 22.04 Master Node Installation

#### 2.1 Pre-Installation State Check
```bash
# Check system state
./system_check_before.sh

# Expected clean state:
# - No Kubernetes components installed
# - No CRI-O installed
# - Swap enabled (default)
# - Required kernel modules not loaded
```

#### 2.2 Master Node Setup
```bash
# Run master setup
sudo bash k8s_master_node.sh 2>&1 | tee master_install.log

# Monitor for errors
grep -i error master_install.log
grep -i failed master_install.log
```

#### 2.3 Master Node Validation
```bash
# Verify installation
./verify_master_setup.sh

# Expected results:
# - kubelet, kubeadm, kubectl installed and correct version
# - CRI-O running
# - Swap disabled
# - Kubernetes control plane initialized
# - Calico CNI installed
# - Node in Ready state
```

### Test 3: Ubuntu 22.04 Worker Node Installation

#### 3.1 Get Join Command
```bash
# From master node
sudo kubeadm token create --print-join-command > join_command.txt
```

#### 3.2 Worker Node Setup
```bash
# On worker node
JOIN_CMD=$(cat join_command.txt)
sudo bash k8s_worker_node.sh "$JOIN_CMD" 2>&1 | tee worker_install.log
```

#### 3.3 Worker Node Validation
```bash
# Verify worker joined cluster
kubectl get nodes
# Expected: Worker node in Ready state
```

### Test 4: Ubuntu 24.04 Testing
Repeat Test 2 and Test 3 on Ubuntu 24.04 LTS

### Test 5: Cluster Functionality Testing

#### 5.1 Pod Scheduling Test
```bash
# Deploy test workload
kubectl create deployment nginx-test --image=nginx:latest --replicas=2
kubectl expose deployment nginx-test --port=80 --type=ClusterIP

# Verify pods running on both nodes
kubectl get pods -o wide
```

#### 5.2 Network Connectivity Test
```bash
# Test pod-to-pod communication
kubectl run test-pod --image=busybox --rm -it -- sh
# Inside pod: nslookup nginx-test
```

#### 5.3 Service Discovery Test
```bash
# Test DNS resolution
kubectl run dns-test --image=busybox --rm -it -- nslookup kubernetes.default
```

## Test Validation Scripts

### System Check Before Installation
Create `system_check_before.sh`:
```bash
#!/bin/bash
echo "=== Pre-Installation System Check ==="
echo "Kubernetes components:"
which kubelet kubeadm kubectl 2>/dev/null || echo "None installed (expected)"
echo "CRI-O status:"
systemctl is-active crio 2>/dev/null || echo "Not running (expected)"
echo "Swap status:"
swapon --show
echo "Kernel modules:"
lsmod | grep -E "(overlay|br_netfilter)" || echo "Not loaded (expected)"
```

### Master Setup Verification
Create `verify_master_setup.sh`:
```bash
#!/bin/bash
echo "=== Master Node Verification ==="

# Check Kubernetes version
kubectl version --client=true
kubeadm version

# Check node status
kubectl get nodes

# Check system pods
kubectl get pods -n kube-system

# Check CRI-O
systemctl is-active crio

# Check kubelet
systemctl is-active kubelet

# Check swap
swapon --show || echo "Swap disabled (correct)"

# Check network
kubectl get pods -n calico-system 2>/dev/null || kubectl get pods -A | grep calico
```

### Worker Setup Verification
Create `verify_worker_setup.sh`:
```bash
#!/bin/bash
echo "=== Worker Node Verification ==="

# Check services
systemctl is-active kubelet
systemctl is-active crio

# Check if joined to cluster
ls -la /etc/kubernetes/kubelet.conf 2>/dev/null && echo "Joined to cluster" || echo "Not joined"

# Check swap
swapon --show || echo "Swap disabled (correct)"
```

## Test Execution Checklist

### Phase 1: Preparation
- [ ] Fix critical issues (shebang, K8s version)
- [ ] Prepare test environments (Ubuntu 22.04, 24.04)
- [ ] Create validation scripts
- [ ] Run static analysis validation

### Phase 2: Ubuntu 22.04 Testing
- [ ] Test master node installation
- [ ] Validate master node setup
- [ ] Test worker node installation
- [ ] Validate worker node setup
- [ ] Test cluster functionality

### Phase 3: Ubuntu 24.04 Testing
- [ ] Repeat all Phase 2 tests on Ubuntu 24.04
- [ ] Compare results between versions

### Phase 4: Production Readiness
- [ ] Document any version-specific issues
- [ ] Create deployment procedures
- [ ] Performance testing (optional)
- [ ] Security scanning (recommended)

## Success Criteria

### Master Node
✅ **All must pass**:
- Script executes without errors
- Kubernetes control plane initialized
- Node shows as Ready
- All system pods Running
- kubeadm join command generated

### Worker Node
✅ **All must pass**:
- Script executes without errors
- Successfully joins cluster
- Node shows as Ready in cluster
- Can schedule pods

### Cluster
✅ **All must pass**:
- Pod-to-pod communication works
- Service discovery functional
- DNS resolution working
- Network policies enforced (if applicable)

## Risk Mitigation

### High Risk Items
1. **Production network conflicts** - Test network CIDR in isolated environment
2. **Package repository issues** - Have local package cache ready
3. **Version compatibility** - Test with specific Ubuntu kernel versions

### Rollback Procedures
Document steps to:
- Remove Kubernetes components
- Restore swap configuration
- Reset network configuration
- Clean up systemd services

## Test Reporting

### Log Collection
For each test, collect:
- Installation logs
- System journal logs (`journalctl -u kubelet -u crio`)
- Kubernetes events (`kubectl get events --all-namespaces`)
- Network configuration (`ip route`, `ip addr`)

### Test Report Template
```
Test Date: [DATE]
Ubuntu Version: [22.04/24.04]
Test Type: [Master/Worker/Cluster]
Result: [PASS/FAIL]
Issues Found: [LIST]
Recommendations: [LIST]
```

## Conclusion
This comprehensive test plan ensures that the Kubernetes setup scripts are production-ready and will work reliably on both Ubuntu 22.04 and 24.04 LTS versions.

**CRITICAL**: Do not use the scripts in production until the identified critical issues are fixed and all tests pass successfully.