#!/bin/bash
# OpenCode Professional Setup Script
# Run this to install and configure your professional opencode setup

set -e

OPENCODE_DIR="${HOME}/.config/opencode"
BACKUP_DIR="${HOME}/.config/opencode.backup.$(date +%Y%m%d_%H%M%S)"

echo "🚀 OpenCode Professional Setup"
echo "================================"

# Backup existing config
if [ -d "$OPENCODE_DIR" ]; then
    echo "📦 Backing up existing config to $BACKUP_DIR"
    mv "$OPENCODE_DIR" "$BACKUP_DIR"
fi

echo "📁 Creating directory structure..."
mkdir -p "$OPENCODE_DIR"/{{agent,commands,skills,context,node_modules}

echo "📦 Installing dependencies..."
cd "$OPENCODE_DIR"
npm install 2>/dev/null || true

echo "🔧 Setting up environment variables..."
# Copy .env.example to .env if .env doesn't exist
if [ ! -f "$OPENCODE_DIR/.env" ]; then
    if [ -f "$OPENCODE_DIR/.env.example" ]; then
        cp "$OPENCODE_DIR/.env.example" "$OPENCODE_DIR/.env"
    fi
fi

echo ""
echo "✅ Setup Complete!"
echo "==================="
echo ""
echo "Next steps:"
echo "1. Edit $OPENCODE_DIR/.env with your API keys"
echo "2. Restart OpenCode to use new configuration"
echo "3. Try: /go for Go workflow"
echo "4. Try: /cpp for C++ workflow"
echo "5. Try: /mobile for React Native"
echo "6. Try: /k8s for Kubernetes"
echo ""
echo "Your agents:"
echo "  - Tab to switch between: build, golang-pro, typescript-pro, cpp-pro, devops-engineer"
echo "  - @golang-pro for Go backend"
echo "  - @typescript-pro for TypeScript/React"
echo "  - @cpp-pro for C++/systems"
echo "  - @mobile-developer for React Native"
echo "  - @devops-engineer for DevOps/SRE"
echo ""
echo "Your skills:"
echo "  - tdd: Test-driven development"
echo "  - go-best-practices: Go idiomatic patterns"
echo "  - cpp-best-practices: Modern C++20/23"
echo "  - react-native-best-practices: Mobile development"
echo "  - observability: Logging, metrics, tracing"
echo "  - dockerfile-best-practices: Container best practices"