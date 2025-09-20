#!/bin/bash

echo "========================================="
echo "Setting up Qwen DevOps Team Agents"
echo "========================================="

# Create Qwen agents directory if it doesn't exist
echo "Creating Qwen agents directory..."
mkdir -p ~/.qwen/agents

# Clear any existing agents to prevent duplicates
echo "Clearing existing agents..."
rm -f ~/.qwen/agents/*.md 2>/dev/null

# Copy agent configurations from the correct location
echo "Installing Docker Optimizer agent..."
mv /root/agents/docker-optimizer.md ~/.qwen/agents/
echo "✅ Docker Optimizer agent installed"

echo "Installing Terraform Security agent..."
mv /root/agents/terraform-security.md ~/.qwen/agents/
echo "✅ Terraform Security agent installed"

# Verify installation
echo ""
echo "Verifying agent installation..."
if [ -f ~/.qwen/agents/docker-optimizer.md ] && [ -f ~/.qwen/agents/terraform-security.md ]; then
    echo "✅ All agents successfully installed!"
    echo ""
    echo "Available agents:"
    echo "  🐳 docker-optimizer    - Optimizes Docker images for ECR"
    echo "  🔒 terraform-security  - Scans Terraform for security issues"
else
    echo "❌ Error: Some agents failed to install"
    exit 1
fi

echo ""
echo "========================================="
echo "Setup Complete!"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Start Qwen interactive mode: qwen"
echo "2. View agents: /agents manage"
echo "3. Create new agents: /agents create"
echo "4. Use agents by describing your needs"
echo ""
echo "Example usage:"
echo '  "Optimize the Docker image in /root/production-issues/bad-docker/"'
echo '  "Check /root/production-issues/bad-terraform/ for security issues"'
echo ""
echo "Note: Qwen will automatically detect which agent to use based on your request!"
echo ""