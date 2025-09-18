#!/bin/bash
# Master Node Setup Verification Script
# Run this after executing k8s_master_node.sh to verify the installation

set -euo pipefail

echo "=== Master Node Verification ==="
echo "Timestamp: $(date)"
echo "Hostname: $(hostname)"
echo

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

success_count=0
warning_count=0
error_count=0

check_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
        ((success_count++))
    else
        echo -e "${RED}✗${NC} $2"
        ((error_count++))
    fi
}

check_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((warning_count++))
}

# Check if running as root or with sudo
if [[ $EUID -eq 0 ]] || sudo -n true 2>/dev/null; then
    echo "✓ Running with appropriate privileges"
else
    echo "⚠ WARNING: Some checks require sudo privileges"
fi
echo

# Check Kubernetes binary versions
echo "--- Kubernetes Components ---"
for cmd in kubectl kubeadm kubelet; do
    if command -v $cmd >/dev/null 2>&1; then
        version=$($cmd --version 2>/dev/null | head -1)
        echo "$cmd: $version"
    else
        check_result 1 "$cmd not installed"
        continue
    fi
done
echo

# Check kubelet service
echo "--- Kubelet Service ---"
if systemctl is-active --quiet kubelet; then
    check_result 0 "kubelet is running"
    kubelet_status=$(systemctl show kubelet -p ActiveState --value)
    echo "  Status: $kubelet_status"
else
    check_result 1 "kubelet is not running"
    echo "  Checking kubelet logs (last 10 lines):"
    sudo journalctl -u kubelet -n 10 --no-pager || true
fi
echo

# Check CRI-O service
echo "--- CRI-O Service ---"
if systemctl is-active --quiet crio; then
    check_result 0 "CRI-O is running"
    crio_version=$(sudo crio --version 2>/dev/null | head -1 || echo "version unknown")
    echo "  Version: $crio_version"
else
    check_result 1 "CRI-O is not running"
    echo "  Checking CRI-O logs (last 10 lines):"
    sudo journalctl -u crio -n 10 --no-pager || true
fi
echo

# Check swap status
echo "--- Swap Configuration ---"
if swapon --show | grep -q .; then
    check_result 1 "Swap is still enabled (should be disabled)"
    swapon --show
else
    check_result 0 "Swap is disabled"
fi
echo

# Check kernel modules
echo "--- Kernel Modules ---"
for module in overlay br_netfilter; do
    if lsmod | grep -q "^$module"; then
        check_result 0 "$module module loaded"
    else
        check_result 1 "$module module not loaded"
    fi
done
echo

# Check sysctl parameters
echo "--- Sysctl Parameters ---"
required_params=(
    "net.bridge.bridge-nf-call-iptables=1"
    "net.bridge.bridge-nf-call-ip6tables=1" 
    "net.ipv4.ip_forward=1"
)

for param in "${required_params[@]}"; do
    key="${param%%=*}"
    expected_value="${param##*=}"
    current_value=$(sysctl -n "$key" 2>/dev/null || echo "unknown")
    
    if [[ "$current_value" == "$expected_value" ]]; then
        check_result 0 "$key = $current_value"
    else
        check_result 1 "$key = $current_value (expected $expected_value)"
    fi
done
echo

# Check if kubeadm init was successful
echo "--- Kubernetes Control Plane ---"
if [[ -f /etc/kubernetes/admin.conf ]]; then
    check_result 0 "kubeadm init completed (admin.conf exists)"
    
    # Set KUBECONFIG for kubectl commands
    export KUBECONFIG=/etc/kubernetes/admin.conf
    
    # Check cluster info
    if kubectl cluster-info >/dev/null 2>&1; then
        check_result 0 "kubectl cluster-info successful"
        echo "  Control plane endpoint: $(kubectl cluster-info | grep 'control plane' | awk '{print $6}' || echo 'unknown')"
    else
        check_result 1 "kubectl cluster-info failed"
    fi
else
    check_result 1 "kubeadm init not completed (admin.conf missing)"
    echo "  Check if k8s_master_node.sh completed successfully"
fi
echo

# Check node status
echo "--- Node Status ---"
if kubectl get nodes >/dev/null 2>&1; then
    echo "Nodes in cluster:"
    kubectl get nodes -o wide || true
    
    # Check if master node is Ready
    master_node=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    if [[ -n "$master_node" ]]; then
        node_status=$(kubectl get node "$master_node" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "Unknown")
        if [[ "$node_status" == "True" ]]; then
            check_result 0 "Master node ($master_node) is Ready"
        else
            check_result 1 "Master node ($master_node) status: $node_status"
        fi
    fi
else
    check_result 1 "Cannot get node status"
fi
echo

# Check system pods
echo "--- System Pods ---"
if kubectl get pods -n kube-system >/dev/null 2>&1; then
    echo "System pods status:"
    kubectl get pods -n kube-system -o wide || true
    echo
    
    # Count pod statuses
    total_pods=$(kubectl get pods -n kube-system --no-headers 2>/dev/null | wc -l || echo "0")
    running_pods=$(kubectl get pods -n kube-system --no-headers 2>/dev/null | grep -c "Running" || echo "0")
    
    echo "System pods summary: $running_pods/$total_pods Running"
    
    if [[ "$running_pods" -eq "$total_pods" ]] && [[ "$total_pods" -gt 0 ]]; then
        check_result 0 "All system pods are Running"
    else
        check_warning "Some system pods may not be ready yet"
    fi
else
    check_result 1 "Cannot get system pods status"
fi
echo

# Check CNI (Calico) installation
echo "--- CNI Network Plugin ---"
calico_pods=$(kubectl get pods -A -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.phase}{"\n"}{end}' 2>/dev/null | grep -c "calico.*Running" || echo "0")
if [[ "$calico_pods" -gt 0 ]]; then
    check_result 0 "Calico CNI pods are running ($calico_pods pods)"
    kubectl get pods -A | grep calico || true
else
    check_warning "Calico CNI pods not found or not running"
    echo "  Check if Calico was installed successfully"
fi
echo

# Check kubeconfig for regular user
echo "--- User Kubeconfig ---"
if [[ -n "${SUDO_USER:-}" ]] && [[ -f "/home/$SUDO_USER/.kube/config" ]]; then
    check_result 0 "kubeconfig exists for user $SUDO_USER"
    
    # Check ownership
    config_owner=$(stat -c '%U' "/home/$SUDO_USER/.kube/config" || echo "unknown")
    if [[ "$config_owner" == "$SUDO_USER" ]]; then
        check_result 0 "kubeconfig has correct ownership"
    else
        check_result 1 "kubeconfig ownership issue (owner: $config_owner, expected: $SUDO_USER)"
    fi
else
    check_warning "User kubeconfig not found or SUDO_USER not set"
fi
echo

# Check join token availability
echo "--- Join Token ---"
if kubeadm token list 2>/dev/null | grep -q authentication; then
    check_result 0 "Join tokens are available"
    echo "  Available tokens:"
    kubeadm token list || true
    echo
    echo "  To get join command for workers:"
    echo "  sudo kubeadm token create --print-join-command"
else
    check_warning "No valid join tokens found"
    echo "  Generate new token: sudo kubeadm token create --print-join-command"
fi
echo

# Network connectivity test
echo "--- Network Connectivity ---"
if kubectl run network-test --image=busybox:1.28 --rm -it --restart=Never --timeout=10s -- nslookup kubernetes.default >/dev/null 2>&1; then
    check_result 0 "DNS resolution working in cluster"
else
    check_warning "DNS resolution test failed or timed out"
fi

# Clean up test pod if it exists
kubectl delete pod network-test 2>/dev/null || true
echo

# Check firewall and network policies
echo "--- Network Configuration ---"
if command -v ufw >/dev/null && ufw status | grep -q "Status: active"; then
    check_warning "UFW firewall is active - ensure required ports are open"
    echo "  Required ports for master node:"
    echo "    - 6443/tcp (API server)"
    echo "    - 2379-2380/tcp (etcd)"
    echo "    - 10250/tcp (kubelet)"
    echo "    - 10259/tcp (kube-scheduler)"
    echo "    - 10257/tcp (kube-controller-manager)"
fi

# Check if the node has a taint (master nodes are tainted by default)
taints=$(kubectl describe node "$(hostname)" 2>/dev/null | grep "Taints:" | cut -d: -f2 | xargs || echo "none")
if [[ "$taints" != "none" ]] && [[ "$taints" != "<none>" ]]; then
    echo "  Node taints: $taints"
    echo "  💡 To allow pod scheduling on master: kubectl taint nodes --all node-role.kubernetes.io/control-plane-"
else
    echo "  Node taints: none (pods can be scheduled on this master)"
fi
echo

# Summary
echo "=== VERIFICATION SUMMARY ==="
echo "Successful checks: $success_count"
echo "Warnings: $warning_count"
echo "Errors: $error_count"
echo

if [[ $error_count -eq 0 ]]; then
    echo -e "${GREEN}✅ Master node setup appears successful!${NC}"
    echo
    echo "Next steps:"
    echo "1. Join worker nodes using: sudo kubeadm token create --print-join-command"
    echo "2. Test cluster functionality with: kubectl get pods -A"
    echo "3. Deploy applications: kubectl create deployment nginx --image=nginx"
elif [[ $error_count -le 2 ]] && [[ $warning_count -gt 0 ]]; then
    echo -e "${YELLOW}⚠️ Master node setup completed with warnings${NC}"
    echo "Review the warnings above and ensure they don't affect your use case"
else
    echo -e "${RED}❌ Master node setup has issues that need attention${NC}"
    echo "Review the errors above and fix them before proceeding"
    echo
    echo "Common troubleshooting steps:"
    echo "1. Check system logs: sudo journalctl -u kubelet -u crio"
    echo "2. Verify network connectivity and DNS"
    echo "3. Ensure all prerequisites are met"
    echo "4. Consider running the installation script again"
fi

echo
echo "=== Verification Complete ==="