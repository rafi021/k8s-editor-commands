#!/bin/bash
# Kubernetes Setup Scripts Validation Tool
# Validates k8s_master_node.sh and k8s_worker_node.sh for common issues

set -euo pipefail

SCRIPTS_PATH="${1:-.}"
MASTER_SCRIPT="$SCRIPTS_PATH/k8s_master_node.sh"
WORKER_SCRIPT="$SCRIPTS_PATH/k8s_worker_node.sh"

echo "=== Kubernetes Setup Scripts Validation ==="

# Check if scripts exist
if [[ ! -f "$MASTER_SCRIPT" ]]; then
    echo "ERROR: Master script not found: $MASTER_SCRIPT"
    exit 1
fi

if [[ ! -f "$WORKER_SCRIPT" ]]; then
    echo "ERROR: Worker script not found: $WORKER_SCRIPT"
    exit 1
fi

echo "✓ Scripts found"

# Function to validate script
validate_script() {
    local script_path="$1"
    local script_type="$2"
    local issues=0
    local warnings=0
    
    echo
    echo "--- Validating $script_type Script ---"
    
    # Check shebang
    if head -1 "$script_path" | grep -q "^#!/.*bash"; then
        echo "✓ Shebang present"
    else
        echo "✗ Missing or incorrect shebang"
        ((issues++))
    fi
    
    # Check for error handling
    if grep -q "set -euo pipefail" "$script_path"; then
        echo "✓ Error handling enabled (set -euo pipefail)"
    else
        echo "✗ Missing 'set -euo pipefail' for error handling"
        ((issues++))
    fi
    
    # Check Kubernetes version
    if k8s_version=$(grep -o 'K8S_VERSION_SHORT="[^"]*"' "$script_path" | cut -d'"' -f2); then
        echo "Found K8s version: $k8s_version"
        
        # Check if version looks valid
        if [[ "$k8s_version" =~ ^1\.3[4-9]\. ]] || [[ "$k8s_version" =~ ^1\.[4-9][0-9]\. ]]; then
            echo "✗ Kubernetes version $k8s_version appears to be invalid or future version"
            ((issues++))
        elif [[ "$k8s_version" =~ ^1\.2[0-9]\. ]] || [[ "$k8s_version" =~ ^1\.3[0-3]\. ]]; then
            echo "✓ Kubernetes version appears valid"
        else
            echo "⚠ Kubernetes version $k8s_version should be verified for availability"
            ((warnings++))
        fi
    else
        echo "✗ Kubernetes version not found or not properly set"
        ((issues++))
    fi
    
    # Check for deprecated repository
    if grep -q "packages\.cloud\.google\.com" "$script_path"; then
        echo "⚠ Using deprecated Google Cloud apt repository - consider migrating to pkgs.k8s.io"
        ((warnings++))
    fi
    
    # Check root permission check
    if grep -q 'if \[\[ \$EUID -ne 0 \]\]' "$script_path"; then
        echo "✓ Root permission check present"
    else
        echo "✗ Missing root permission check"
        ((issues++))
    fi
    
    # Check for Ubuntu version detection
    if grep -q 'case "\$OS_VERSION_ID"' "$script_path"; then
        echo "✓ Ubuntu version detection present"
    else
        echo "✗ Missing Ubuntu version detection"
        ((issues++))
    fi
    
    # Check for swap disable
    if grep -q "swapoff -a" "$script_path"; then
        echo "✓ Swap disable present"
    else
        echo "✗ Missing swap disable command"
        ((issues++))
    fi
    
    # Check for kernel modules
    if grep -q "modprobe overlay" "$script_path" && grep -q "modprobe br_netfilter" "$script_path"; then
        echo "✓ Kernel modules loading present"
    else
        echo "✗ Missing kernel modules loading (overlay, br_netfilter)"
        ((issues++))
    fi
    
    # Check for systemctl commands
    if grep -q "systemctl.*enable.*crio" "$script_path" && grep -q "systemctl.*enable.*kubelet" "$script_path"; then
        echo "✓ Service enablement present"
    else
        echo "⚠ Check service enablement commands"
        ((warnings++))
    fi
    
    # Check for network CIDR (master only)
    if [[ "$script_type" == "Master" ]] && pod_cidr=$(grep -o 'POD_NETWORK_CIDR="[^"]*"' "$script_path" | cut -d'"' -f2); then
        echo "Pod network CIDR: $pod_cidr"
        if [[ "$pod_cidr" == "192.168.0.0/16" ]]; then
            echo "⚠ POD_NETWORK_CIDR uses 192.168.0.0/16 which may conflict with local networks"
            ((warnings++))
        fi
    fi
    
    # Summary for this script
    echo
    echo "$script_type Script Summary:"
    echo "  Issues: $issues"
    echo "  Warnings: $warnings"
    
    return $((issues * 10 + warnings))
}

# Validate both scripts
validate_script "$MASTER_SCRIPT" "Master"
master_result=$?

validate_script "$WORKER_SCRIPT" "Worker"
worker_result=$?

# Calculate totals
total_issues=$(( (master_result / 10) + (worker_result / 10) ))
total_warnings=$(( (master_result % 10) + (worker_result % 10) ))

echo
echo "=== OVERALL VALIDATION SUMMARY ==="
echo "Total Critical Issues: $total_issues"
echo "Total Warnings: $total_warnings"

if [[ $total_issues -gt 0 ]]; then
    echo
    echo "❌ SCRIPTS REQUIRE FIXES BEFORE PRODUCTION USE"
    exit 1
elif [[ $total_warnings -gt 0 ]]; then
    echo
    echo "⚠️  SCRIPTS HAVE WARNINGS - REVIEW RECOMMENDED"
    exit 2
else
    echo
    echo "✅ SCRIPTS VALIDATION PASSED"
    exit 0
fi