#!/bin/bash
# Worker Node Setup Verification Script
# Run this after executing k8s_worker_node.sh to verify the installation

set -euo pipefail

echo "=== Worker Node Verification ==="
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

# Check if worker joined the cluster
echo "--- Cluster Membership ---"
if [[ -f /etc/kubernetes/kubelet.conf ]]; then
    check_result 0 "Worker joined cluster (kubelet.conf exists)"
    
    # Check kubelet configuration
    if [[ -f /var/lib/kubelet/config.yaml ]]; then
        check_result 0 "kubelet configuration exists"
    else
        check_warning "kubelet configuration file not found"
    fi
    
else
    check_result 1 "Worker not joined to cluster (kubelet.conf missing)"
    echo "  Check if k8s_worker_node.sh completed successfully"
    echo "  Ensure join command was valid and master node is reachable"
fi
echo

# Check node certificates
echo "--- Node Certificates ---"
cert_files=(
    "/var/lib/kubelet/pki/kubelet-client-current.pem"
    "/var/lib/kubelet/pki/kubelet.crt"
    "/var/lib/kubelet/pki/kubelet.key"
)

for cert_file in "${cert_files[@]}"; do
    if [[ -f "$cert_file" ]]; then
        check_result 0 "Certificate exists: $(basename "$cert_file")"
    else
        check_result 1 "Certificate missing: $(basename "$cert_file")"
    fi
done
echo

# Try to contact the API server (this requires network connectivity to master)
echo "--- API Server Connectivity ---"
if [[ -f /etc/kubernetes/kubelet.conf ]]; then
    # Extract API server endpoint from kubelet config
    api_server=$(grep -o 'https://[^"]*' /etc/kubernetes/kubelet.conf | head -1 || echo "")
    if [[ -n "$api_server" ]]; then
        echo "API Server: $api_server"
        
        # Test connectivity to API server
        if timeout 5 bash -c "echo >/dev/tcp/${api_server#https://}" 2>/dev/null; then
            check_result 0 "Can reach API server"
        else
            check_result 1 "Cannot reach API server (check network and firewall)"
        fi
    else
        check_warning "Cannot extract API server endpoint from kubelet config"
    fi
else
    check_warning "Cannot test API server connectivity (not joined to cluster)"
fi
echo

# Check container runtime socket
echo "--- Container Runtime Socket ---"
crio_socket="/var/run/crio/crio.sock"
if [[ -S "$crio_socket" ]]; then
    check_result 0 "CRI-O socket exists and is accessible"
else
    check_result 1 "CRI-O socket not found or not accessible"
fi
echo

# Check if kubelet can pull images
echo "--- Container Image Management ---"
if systemctl is-active --quiet crio && [[ -S "$crio_socket" ]]; then
    # Try to list images (this tests if CRI-O is responding)
    if sudo crictl images >/dev/null 2>&1; then
        check_result 0 "Can communicate with container runtime"
        image_count=$(sudo crictl images -q | wc -l || echo "0")
        echo "  Container images available: $image_count"
    else
        check_result 1 "Cannot communicate with container runtime"
    fi
else
    check_warning "Cannot test container runtime (CRI-O not running or socket unavailable)"
fi
echo

# Check kubelet configuration
echo "--- Kubelet Configuration ---"
if [[ -f /var/lib/kubelet/config.yaml ]]; then
    # Check important configuration settings
    if grep -q "cgroupDriver.*systemd" /var/lib/kubelet/config.yaml 2>/dev/null; then
        check_result 0 "kubelet using systemd cgroup driver"
    else
        check_warning "kubelet cgroup driver configuration unclear"
    fi
    
    if grep -q "containerRuntimeEndpoint.*crio.sock" /var/lib/kubelet/config.yaml 2>/dev/null; then
        check_result 0 "kubelet configured to use CRI-O"
    else
        check_warning "kubelet container runtime endpoint configuration unclear"
    fi
else
    check_warning "kubelet configuration file not found"
fi
echo

# Check system resource usage
echo "--- System Resources ---"
echo "Current resource usage:"
echo "  CPU load: $(uptime | awk -F'load average:' '{print $2}' | xargs)"
echo "  Memory usage: $(free -h | awk '/^Mem:/ {printf "%s/%s (%.1f%%)", $3, $2, ($3/$2)*100}')"
echo "  Disk usage: $(df -h / | awk 'NR==2 {printf "%s/%s (%s)", $3, $2, $5}')"
echo

# Check network configuration
echo "--- Network Configuration ---"
default_route=$(ip route | grep default | head -1 || echo "no default route")
echo "Default route: $default_route"

if command -v ufw >/dev/null && ufw status | grep -q "Status: active"; then
    check_warning "UFW firewall is active - ensure required ports are open"
    echo "  Required ports for worker node:"
    echo "    - 10250/tcp (kubelet API)"
    echo "    - 30000-32767/tcp (NodePort services)"
fi
echo

# Summary
echo "=== VERIFICATION SUMMARY ==="
echo "Successful checks: $success_count"
echo "Warnings: $warning_count"
echo "Errors: $error_count"
echo

if [[ $error_count -eq 0 ]]; then
    echo -e "${GREEN}✅ Worker node setup appears successful!${NC}"
    echo
    echo "Next steps:"
    echo "1. Verify from master node: kubectl get nodes"
    echo "2. Check if node shows as 'Ready'"
    echo "3. Test pod scheduling: kubectl create deployment nginx --image=nginx"
    echo "4. Verify pod runs on this worker: kubectl get pods -o wide"
elif [[ $error_count -le 2 ]] && [[ $warning_count -gt 0 ]]; then
    echo -e "${YELLOW}⚠️ Worker node setup completed with warnings${NC}"
    echo "Review the warnings above and ensure they don't affect your use case"
else
    echo -e "${RED}❌ Worker node setup has issues that need attention${NC}"
    echo "Review the errors above and fix them before proceeding"
    echo
    echo "Common troubleshooting steps:"
    echo "1. Check system logs: sudo journalctl -u kubelet -u crio"
    echo "2. Verify network connectivity to master node"
    echo "3. Ensure join command was correct and not expired"
    echo "4. Check firewall settings and required ports"
    echo "5. Consider re-running the worker installation script"
    echo
    echo "To rejoin the cluster:"
    echo "1. Get new join command from master: sudo kubeadm token create --print-join-command"
    echo "2. Reset this node: sudo kubeadm reset"
    echo "3. Run the join command again"
fi

echo
echo "=== Verification Complete ==="