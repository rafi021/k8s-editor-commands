#!/usr/bin/env python3
"""
Kubernetes Setup Scripts Validation Tool
Validates k8s_master_node.sh and k8s_worker_node.sh for common issues
"""

import sys
import os
import re
from pathlib import Path

def validate_script(script_path, script_type):
    """Validate a single script file"""
    issues = []
    warnings = []
    
    print(f"\n--- Validating {script_type} Script ---")
    
    try:
        with open(script_path, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception as e:
        print(f"ERROR: Cannot read script: {e}")
        return [], []
    
    # Check shebang
    if content.startswith('#!/usr/bin/env bash') or content.startswith('#!/bin/bash'):
        print("✓ Shebang present")
    else:
        print("✗ Missing or incorrect shebang")
        issues.append("Missing or incorrect shebang")
    
    # Check for error handling
    if 'set -euo pipefail' in content:
        print("✓ Error handling enabled (set -euo pipefail)")
    else:
        print("✗ Missing 'set -euo pipefail' for error handling")
        issues.append("Missing 'set -euo pipefail' for error handling")
    
    # Check Kubernetes version
    version_match = re.search(r'K8S_VERSION_SHORT="([^"]+)"', content)
    if version_match:
        version = version_match.group(1)
        print(f"Found K8s version: {version}")
        
        # Check if version looks valid
        if re.match(r'^1\.3[4-9]\.', version) or re.match(r'^1\.[4-9][0-9]\.', version):
            print(f"✗ Kubernetes version {version} appears to be invalid or future version")
            issues.append(f"Kubernetes version {version} appears to be invalid or future version")
        elif re.match(r'^1\.2[0-9]\.', version) or re.match(r'^1\.3[0-3]\.', version):
            print("✓ Kubernetes version appears valid")
        else:
            print(f"⚠ Kubernetes version {version} should be verified for availability")
            warnings.append(f"Kubernetes version {version} should be verified for availability")
    else:
        print("✗ Kubernetes version not found or not properly set")
        issues.append("Kubernetes version not found or not properly set")
    
    # Check for deprecated repository
    if 'packages.cloud.google.com' in content:
        print("⚠ Using deprecated Google Cloud apt repository - consider migrating to pkgs.k8s.io")
        warnings.append("Using deprecated Google Cloud apt repository - consider migrating to pkgs.k8s.io")
    
    # Check root permission check
    if 'if [[ $EUID -ne 0 ]]' in content:
        print("✓ Root permission check present")
    else:
        print("✗ Missing root permission check")
        issues.append("Missing root permission check")
    
    # Check for Ubuntu version detection
    if 'case "$OS_VERSION_ID"' in content:
        print("✓ Ubuntu version detection present")
    else:
        print("✗ Missing Ubuntu version detection")
        issues.append("Missing Ubuntu version detection")
    
    # Check for swap disable
    if 'swapoff -a' in content:
        print("✓ Swap disable present")
    else:
        print("✗ Missing swap disable command")
        issues.append("Missing swap disable command")
    
    # Check for kernel modules
    if 'modprobe overlay' in content and 'modprobe br_netfilter' in content:
        print("✓ Kernel modules loading present")
    else:
        print("✗ Missing kernel modules loading (overlay, br_netfilter)")
        issues.append("Missing kernel modules loading (overlay, br_netfilter)")
    
    # Check for systemctl commands
    if re.search(r'systemctl.*enable.*crio', content) and re.search(r'systemctl.*enable.*kubelet', content):
        print("✓ Service enablement present")
    else:
        print("⚠ Check service enablement commands")
        warnings.append("Check service enablement commands")
    
    # Check for network CIDR (master only)
    if script_type == "Master":
        cidr_match = re.search(r'POD_NETWORK_CIDR="([^"]+)"', content)
        if cidr_match:
            cidr = cidr_match.group(1)
            print(f"Pod network CIDR: {cidr}")
            if cidr == "192.168.0.0/16":
                print("⚠ POD_NETWORK_CIDR uses 192.168.0.0/16 which may conflict with local networks")
                warnings.append("POD_NETWORK_CIDR uses 192.168.0.0/16 which may conflict with local networks")
    
    # Summary for this script
    print(f"\n{script_type} Script Summary:")
    print(f"  Issues: {len(issues)}")
    print(f"  Warnings: {len(warnings)}")
    
    if issues:
        print("  Critical Issues:")
        for issue in issues:
            print(f"    - {issue}")
    
    if warnings:
        print("  Warnings:")
        for warning in warnings:
            print(f"    - {warning}")
    
    return issues, warnings

def main():
    scripts_path = sys.argv[1] if len(sys.argv) > 1 else "."
    master_script = Path(scripts_path) / "k8s_master_node.sh"
    worker_script = Path(scripts_path) / "k8s_worker_node.sh"
    
    print("=== Kubernetes Setup Scripts Validation ===")
    
    # Check if scripts exist
    if not master_script.exists():
        print(f"ERROR: Master script not found: {master_script}")
        sys.exit(1)
    
    if not worker_script.exists():
        print(f"ERROR: Worker script not found: {worker_script}")
        sys.exit(1)
    
    print("✓ Scripts found")
    
    # Validate both scripts
    master_issues, master_warnings = validate_script(master_script, "Master")
    worker_issues, worker_warnings = validate_script(worker_script, "Worker")
    
    # Calculate totals
    total_issues = len(master_issues) + len(worker_issues)
    total_warnings = len(master_warnings) + len(worker_warnings)
    
    print("\n=== OVERALL VALIDATION SUMMARY ===")
    print(f"Total Critical Issues: {total_issues}")
    print(f"Total Warnings: {total_warnings}")
    
    if total_issues > 0:
        print("\n❌ SCRIPTS REQUIRE FIXES BEFORE PRODUCTION USE")
        sys.exit(1)
    elif total_warnings > 0:
        print("\n⚠️  SCRIPTS HAVE WARNINGS - REVIEW RECOMMENDED")
        sys.exit(2)
    else:
        print("\n✅ SCRIPTS VALIDATION PASSED")
        sys.exit(0)

if __name__ == "__main__":
    main()