# Kubernetes Setup Scripts Validation Tool
# Validates k8s_master_node.sh and k8s_worker_node.sh for common issues

param(
    [string]$ScriptsPath = ".",
    [switch]$Detailed = $false
)

Write-Host "=== Kubernetes Setup Scripts Validation ===" -ForegroundColor Green

# Check if scripts exist
$masterScript = Join-Path $ScriptsPath "k8s_master_node.sh"
$workerScript = Join-Path $ScriptsPath "k8s_worker_node.sh"

if (!(Test-Path $masterScript)) {
    Write-Error "Master script not found: $masterScript"
    exit 1
}

if (!(Test-Path $workerScript)) {
    Write-Error "Worker script not found: $workerScript"
    exit 1
}

Write-Host "✓ Scripts found" -ForegroundColor Green

# Function to check script content
function Test-ScriptContent {
    param($FilePath, $ScriptType)
    
    Write-Host "`n--- Validating $ScriptType Script ---" -ForegroundColor Yellow
    
    $content = Get-Content $FilePath -Raw
    $issues = @()
    $warnings = @()
    
    # Check shebang
    if (!$content.StartsWith("#!/usr/bin/env bash") -and !$content.StartsWith("#!/bin/bash")) {
        $issues += "Missing or incorrect shebang"
    } else {
        Write-Host "✓ Shebang present" -ForegroundColor Green
    }
    
    # Check for set -euo pipefail
    if ($content -match "set -euo pipefail") {
        Write-Host "✓ Error handling enabled (set -euo pipefail)" -ForegroundColor Green
    } else {
        $issues += "Missing 'set -euo pipefail' for error handling"
    }
    
    # Check Kubernetes version
    if ($content -match 'K8S_VERSION_SHORT="([^"]+)"') {
        $version = $matches[1]
        Write-Host "Found K8s version: $version" -ForegroundColor Cyan
        
        # Check if version looks valid (should be like 1.29.0, not 1.34.1)
        if ($version -match "^1\.3[4-9]\." -or $version -match "^1\.[4-9][0-9]\.") {
            $issues += "Kubernetes version $version appears to be invalid or future version"
        } elseif ($version -match "^1\.2[0-9]\." -or $version -match "^1\.3[0-3]\.") {
            Write-Host "✓ Kubernetes version appears valid" -ForegroundColor Green
        } else {
            $warnings += "Kubernetes version $version should be verified for availability"
        }
    } else {
        $issues += "Kubernetes version not found or not properly set"
    }
    
    # Check for deprecated repository
    if ($content -match "packages\.cloud\.google\.com") {
        $warnings += "Using deprecated Google Cloud apt repository - consider migrating to pkgs.k8s.io"
    }
    
    # Check root permission check
    if ($content -match 'if \[\[ \$EUID -ne 0 \]\]') {
        Write-Host "✓ Root permission check present" -ForegroundColor Green
    } else {
        $issues += "Missing root permission check"
    }
    
    # Check for Ubuntu version detection
    if ($content -match 'case "\$OS_VERSION_ID"') {
        Write-Host "✓ Ubuntu version detection present" -ForegroundColor Green
    } else {
        $issues += "Missing Ubuntu version detection"
    }
    
    # Check for swap disable
    if ($content -match "swapoff -a") {
        Write-Host "✓ Swap disable present" -ForegroundColor Green
    } else {
        $issues += "Missing swap disable command"
    }
    
    # Check for kernel modules
    if ($content -match "modprobe overlay" -and $content -match "modprobe br_netfilter") {
        Write-Host "✓ Kernel modules loading present" -ForegroundColor Green
    } else {
        $issues += "Missing kernel modules loading (overlay, br_netfilter)"
    }
    
    # Check for systemctl commands
    if ($content -match "systemctl.*enable.*crio" -and $content -match "systemctl.*enable.*kubelet") {
        Write-Host "✓ Service enablement present" -ForegroundColor Green
    } else {
        $warnings += "Check service enablement commands"
    }
    
    # Check for network CIDR (master only)
    if ($ScriptType -eq "Master" -and $content -match 'POD_NETWORK_CIDR="([^"]+)"') {
        $cidr = $matches[1]
        if ($cidr -eq "192.168.0.0/16") {
            $warnings += "POD_NETWORK_CIDR uses 192.168.0.0/16 which may conflict with local networks"
        }
        Write-Host "Pod network CIDR: $cidr" -ForegroundColor Cyan
    }
    
    # Summary for this script
    Write-Host "`n$ScriptType Script Summary:" -ForegroundColor Magenta
    Write-Host "  Issues: $($issues.Count)" -ForegroundColor $(if($issues.Count -gt 0) {"Red"} else {"Green"})
    Write-Host "  Warnings: $($warnings.Count)" -ForegroundColor $(if($warnings.Count -gt 0) {"Yellow"} else {"Green"})
    
    if ($issues.Count -gt 0) {
        Write-Host "  Critical Issues:" -ForegroundColor Red
        $issues | ForEach-Object { Write-Host "    - $_" -ForegroundColor Red }
    }
    
    if ($warnings.Count -gt 0) {
        Write-Host "  Warnings:" -ForegroundColor Yellow
        $warnings | ForEach-Object { Write-Host "    - $_" -ForegroundColor Yellow }
    }
    
    return @{
        Issues = $issues
        Warnings = $warnings
    }
}

# Validate both scripts
$masterResults = Test-ScriptContent $masterScript "Master"
$workerResults = Test-ScriptContent $workerScript "Worker"

# Overall summary
Write-Host "`n=== OVERALL VALIDATION SUMMARY ===" -ForegroundColor Green
$totalIssues = $masterResults.Issues.Count + $workerResults.Issues.Count
$totalWarnings = $masterResults.Warnings.Count + $workerResults.Warnings.Count

Write-Host "Total Critical Issues: $totalIssues" -ForegroundColor $(if($totalIssues -gt 0) {"Red"} else {"Green"})
Write-Host "Total Warnings: $totalWarnings" -ForegroundColor $(if($totalWarnings -gt 0) {"Yellow"} else {"Green"})

if ($totalIssues -gt 0) {
    Write-Host "`n❌ SCRIPTS REQUIRE FIXES BEFORE PRODUCTION USE" -ForegroundColor Red
    exit 1
} elseif ($totalWarnings -gt 0) {
    Write-Host "`n⚠️  SCRIPTS HAVE WARNINGS - REVIEW RECOMMENDED" -ForegroundColor Yellow
    exit 2
} else {
    Write-Host "`n✅ SCRIPTS VALIDATION PASSED" -ForegroundColor Green
    exit 0
}