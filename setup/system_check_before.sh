#!/bin/bash
# Pre-Installation System Check for Kubernetes Setup Scripts
# Run this script before executing k8s_master_node.sh or k8s_worker_node.sh

set -euo pipefail

echo "=== Pre-Installation System Check ==="
echo "Timestamp: $(date)"
echo "Hostname: $(hostname)"
echo "User: $(whoami)"
echo

# Check OS version
echo "--- Operating System ---"
if [ -f /etc/os-release ]; then
    source /etc/os-release
    echo "OS: $NAME $VERSION"
    echo "Version ID: $VERSION_ID"
    
    # Check if supported version
    if [[ "$VERSION_ID" == "22.04" || "$VERSION_ID" == "24.04" ]]; then
        echo "✓ Supported Ubuntu version"
    else
        echo "⚠ WARNING: Untested Ubuntu version. Supported: 22.04, 24.04"
    fi
else
    echo "✗ Cannot detect OS version"
fi
echo

# Check hardware resources
echo "--- Hardware Resources ---"
echo "CPU cores: $(nproc)"
echo "Memory: $(free -h | awk '/^Mem:/ {print $2}')"
echo "Disk space: $(df -h / | awk 'NR==2 {print $4}' | sed 's/G/ GB/')"

# Minimum requirements check
cpu_cores=$(nproc)
mem_gb=$(free -m | awk '/^Mem:/ {printf "%.1f", $2/1024}')
disk_gb=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')

echo
echo "Resource Requirements Check:"
[[ $cpu_cores -ge 2 ]] && echo "✓ CPU: $cpu_cores cores (≥2 required)" || echo "✗ CPU: $cpu_cores cores (need ≥2)"
[[ $(echo "$mem_gb >= 2" | bc -l) == 1 ]] && echo "✓ Memory: ${mem_gb}GB (≥2GB required)" || echo "✗ Memory: ${mem_gb}GB (need ≥2GB)"
[[ $disk_gb -ge 20 ]] && echo "✓ Disk: ${disk_gb}GB (≥20GB required)" || echo "✗ Disk: ${disk_gb}GB (need ≥20GB)"
echo

# Check internet connectivity
echo "--- Network Connectivity ---"
if ping -c 1 8.8.8.8 &>/dev/null; then
    echo "✓ Internet connectivity available"
else
    echo "✗ No internet connectivity (required for package downloads)"
fi

if ping -c 1 packages.cloud.google.com &>/dev/null; then
    echo "✓ Can reach Kubernetes package repository"
else
    echo "⚠ Cannot reach packages.cloud.google.com"
fi
echo

# Check existing Kubernetes components
echo "--- Existing Kubernetes Components ---"
echo "Kubernetes binaries:"
for cmd in kubelet kubeadm kubectl; do
    if command -v $cmd >/dev/null 2>&1; then
        version=$($cmd --version 2>/dev/null | head -1)
        echo "  $cmd: $version (already installed)"
    else
        echo "  $cmd: not installed (expected)"
    fi
done
echo

# Check container runtime
echo "--- Container Runtime ---"
if systemctl is-active --quiet crio 2>/dev/null; then
    echo "CRI-O: $(systemctl is-active crio) (version: $(crio --version | head -1))"
else
    echo "CRI-O: not running (expected for fresh install)"
fi

if systemctl is-active --quiet docker 2>/dev/null; then
    echo "⚠ Docker is running - may conflict with CRI-O"
else
    echo "Docker: not running (good)"
fi

if systemctl is-active --quiet containerd 2>/dev/null; then
    echo "⚠ containerd is running - may conflict with CRI-O"
else
    echo "containerd: not running (good)"
fi
echo

# Check swap status
echo "--- Swap Configuration ---"
if swapon --show | grep -q .; then
    echo "Swap status: enabled"
    swapon --show
    echo "⚠ Swap will be disabled during installation"
else
    echo "Swap status: disabled (already configured)"
fi
echo

# Check required kernel modules
echo "--- Kernel Modules ---"
for module in overlay br_netfilter; do
    if lsmod | grep -q "^$module"; then
        echo "$module: loaded"
    else
        echo "$module: not loaded (will be loaded during installation)"
    fi
done
echo

# Check systemd services
echo "--- Systemd Services ---"
for service in kubelet crio; do
    if systemctl is-enabled --quiet $service 2>/dev/null; then
        status=$(systemctl is-active $service 2>/dev/null || echo "inactive")
        echo "$service: enabled, status: $status"
    else
        echo "$service: not enabled (expected for fresh install)"
    fi
done
echo

# Check firewall status
echo "--- Firewall Status ---"
if command -v ufw >/dev/null && ufw status | grep -q "Status: active"; then
    echo "UFW firewall: active"
    echo "⚠ Firewall is enabled - ensure required ports are open:"
    echo "  Master: 6443, 2379-2380, 10250, 10259, 10257"
    echo "  Worker: 10250, 30000-32767"
else
    echo "UFW firewall: inactive or not installed"
fi

if systemctl is-active --quiet iptables 2>/dev/null; then
    echo "iptables: active"
else
    echo "iptables: not active"
fi
echo

# Check system updates
echo "--- System Updates ---"
echo "Checking for available updates..."
if apt list --upgradable 2>/dev/null | grep -q upgradable; then
    update_count=$(apt list --upgradable 2>/dev/null | grep -c upgradable || echo "0")
    echo "Available updates: $update_count packages"
    echo "💡 Consider running 'sudo apt update && sudo apt upgrade' before installation"
else
    echo "System is up to date"
fi
echo

# Final recommendations
echo "=== RECOMMENDATIONS ==="
echo "1. Ensure you have root/sudo privileges"
echo "2. Run 'sudo apt update' before installation"
echo "3. Backup important data before proceeding"
echo "4. Ensure stable network connectivity during installation"
echo "5. Review the comprehensive test plan before production deployment"

# Check root privileges
echo
if [[ $EUID -eq 0 ]]; then
    echo "✓ Running as root"
elif sudo -n true 2>/dev/null; then
    echo "✓ Sudo access available"
else
    echo "⚠ WARNING: No root privileges detected. Installation requires sudo access."
fi

echo
echo "=== System Check Complete ==="
echo "Review the output above before proceeding with Kubernetes installation."