# Agent Directory Structure

This directory contains organized agent definitions grouped by functional area for better maintainability and accessibility.

## Directory Structure

### 🏗️ Architecture (4 agents)
- **api-designer.md** - API architecture expert for REST and GraphQL
- **architect-reviewer.md** - Code architecture review and design patterns
- **cloud-architect.md** - Multi-cloud strategies and scalable architectures
- **graphql-architect.md** - GraphQL schema and API graph design

### ⚙️ Backend (6 agents)
- **backend-developer.md** - Senior backend development
- **cpp-pro.md** - Modern C++ development
- **golang-pro.md** - Go systems programming
- **python-pro.md** - Python 3.11+ and ecosystem
- **rust-engineer.md** - Rust systems programming
- **sql-pro.md** - SQL query optimization

### 💾 Data (2 agents)
- **database-administrator.md** - Database management and optimization
- **postgres-pro.md** - PostgreSQL specialist

### 🔧 DevOps (5 agents)
- **azure-infra-engineer.md** - Azure cloud infrastructure
- **deployment-engineer.md** - CI/CD pipelines and deployment
- **devops-engineer.md** - DevOps automation and infrastructure
- **kubernetes-specialist.md** - Container orchestration
- **terraform-engineer.md** - Infrastructure as Code

### 🎨 Frontend (4 agents)
- **frontend-developer.md** - Frontend development
- **javascript-pro.md** - Modern JavaScript development
- **nextjs-developer.md** - Next.js full-stack framework
- **react-specialist.md** - React component development

### 🔄 Fullstack (1 agent)
- **fullstack-developer.md** - Full-stack development

### 🚨 Incident Response (4 agents)
- **debugger.md** - Debugging and troubleshooting
- **devops-incident-responder.md** - DevOps incident management
- **error-detective.md** - Error pattern analysis
- **incident-responder.md** - Security incident response

### 🌐 Infrastructure (3 agents)
- **build-engineer.md** - Build system optimization
- **network-engineer.md** - Network design and security
- **platform-engineer.md** - Platform engineering and tooling

### 📱 Mobile (3 agents)
- **game-developer.md** - Game engine programming
- **mobile-app-developer.md** - Native iOS and Android
- **mobile-developer.md** - Cross-platform development

### ✅ Quality (2 agents)
- **code-reviewer.md** - Code quality and best practices
- **security-engineer.md** - Security engineering

### 🎯 Specialized (5 agents)
- **dependency-manager.md** - Dependency management
- **payment-integration.md** - Payment gateway integration
- **refactoring-specialist.md** - Code refactoring and optimization
- **seo-specialist.md** - SEO strategies and optimization
- **sre-engineer.md** - Site reliability engineering

### 🛠️ Tools (7 agents)
- **cli-developer.md** - Command-line interface design
- **context-manager.md** - Context management and synchronization
- **dx-optimizer.md** - Developer experience optimization
- **git-workflow-manager.md** - Git workflow management
- **multi-agent-coordinator.md** - Multi-agent coordination
- **task-distributor.md** - Task distribution and load balancing
- **tooling-engineer.md** - Developer tooling

### 🎭 UX (4 agents)
- **commit.md** - Git commit automation
- **documentation-engineer.md** - Documentation systems
- **ui-designer.md** - UI design and aesthetics
- **ux-researcher.md** - UX research and user insights

## Quick Navigation

- **Need an API design?** → Check `architecture/`
- **Building a backend service?** → Check `backend/`
- **Deploying to production?** → Check `devops/`
- **Creating a user interface?** → Check `frontend/`
- **Managing incidents?** → Check `incident-response/`
- **Ensuring code quality?** → Check `quality/`
- **Need database help?** → Check `data/`
- **Setting up CI/CD?** → Check `devops/` or `tools/`

## Agent File Format

Each agent file is a markdown file with YAML frontmatter:

```yaml
---
name: agent-name
description: Brief description
mode: subagent/primary
permission:
  edit: allow/deny
  bash: allow/deny
  webfetch: allow/deny
tools:
  write: true/false
  edit: true/false
  read: true/false
---

[Agent description and instructions]
```

## Maintenance

When adding new agents:
1. Place them in the most appropriate subdirectory
2. Follow the naming convention: `agent-name.md`
3. Include proper frontmatter metadata
4. Update this README if needed

## Total Count

- **15 categories** of agents
- **50 agent files** total
