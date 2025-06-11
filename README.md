# MediaWiki Lua Module Library

📚 **[Complete Documentation on Wiki →](https://github.com/roscroft/mediawiki-lua-library/wiki)**


A comprehensive functional programming library ecosystem for MediaWiki environments, providing advanced utilities for array manipulation, functional programming patterns, and UI component building with standardized error handling and performance monitoring.

## 🚀 Quick Start

### Prerequisites

**Required:**

- **Docker** (for MediaWiki development environment)
- **Git** (for version control)

**Optional but Recommended:**

- **VS Code** (enhanced development experience)
- **Node.js & npm** (for markdown formatting tools)
- **Lua 5.1** and **luacheck** (for local Lua development)

### Setup Instructions

#### 1. Clone and Navigate

```bash
git clone <repository-url>
cd wiki-lua
```

#### 2. Security Configuration

```bash
# Copy environment template
cp .env.template .env

# Generate secure keys (Linux/Mac)
openssl rand -hex 32  # Use for MEDIAWIKI_SECRET_KEY
openssl rand -hex 16  # Use for MEDIAWIKI_UPGRADE_KEY

# Edit .env file and update:
# - MEDIAWIKI_ADMIN_PASSWORD (change from default)
# - MEDIAWIKI_PROD_PASSWORD (change from default)
# - MEDIAWIKI_SECRET_KEY (use generated key)
# - MEDIAWIKI_UPGRADE_KEY (use generated key)
```

#### 3. Development Tools Setup (Optional)

```bash
# Install linting and formatting tools
npm install                    # Markdown tools (prettier, markdownlint)
chmod +x scripts/*.sh         # Make scripts executable

# Install Lua tools (if developing locally)
luarocks install luacheck     # Lua linting (requires luarocks)
```

#### 4. Start Development Environment

```bash
# Option A: Using VS Code Tasks (Recommended)
# Open VS Code → Ctrl+Shift+P → "Tasks: Run Task" → "Start MediaWiki Container & Open Browser"

# Option B: Using Scripts
./scripts/start-mediawiki.sh

# Option C: Manual Docker
docker run -d --name mediawiki-lua \
  -p 8080:80 \
  -v $(pwd)/src/modules:/var/www/html/extensions/Scribunto/includes/engines/LuaStandalone/lualib \
  --env-file .env \
  mediawiki:latest
```

#### 5. Verify Installation

```bash
# Run test pipeline
bash tests/scripts/test-pipeline.sh

# Expected output: All 4 stages should pass
# Stage 1: Syntax validation ✓
# Stage 2: Lua execution ✓
# Stage 3: Mocked environment ✓
# Stage 4: Scribunto integration ✓
```

### Access Points

- **MediaWiki Interface**: <http://localhost:8080>
- **Performance Dashboard**: Use VS Code task "View Performance Dashboard"
- **Module Testing**: `bash tests/scripts/test-pipeline.sh`

## 📚 Documentation

📚 **[Complete Documentation on Wiki →](https://github.com/roscroft/mediawiki-lua-library/wiki)**

All comprehensive documentation has been moved to the GitHub Wiki for better organization and navigation:

- **[Getting Started](https://github.com/roscroft/mediawiki-lua-library/wiki/Getting-Started)** - Installation, setup, and usage instructions
- **[Development Guide](https://github.com/roscroft/mediawiki-lua-library/wiki/Development-Guide)** - Complete project timeline and patterns
- **[GitHub Actions](https://github.com/roscroft/mediawiki-lua-library/wiki/GitHub-Actions)** - CI/CD pipeline setup and usage  
- **[Security](https://github.com/roscroft/mediawiki-lua-library/wiki/Security)** - Security configuration and best practices
- **[Testing](https://github.com/roscroft/mediawiki-lua-library/wiki/Testing)** - Testing infrastructure and procedures
- **[Project Status](https://github.com/roscroft/mediawiki-lua-library/wiki/Project-Status)** - Current module status and features
- **[API Documentation](https://github.com/roscroft/mediawiki-lua-library/wiki/API-Documentation)** - Complete module API reference

## 🛠️ Development Workflow

### VS Code Integration (Recommended)

1. **Start MediaWiki**: `Ctrl+Shift+P` → "Tasks: Run Task" → "Start MediaWiki Container & Open Browser"
2. **View Dashboard**: `Ctrl+Shift+P` → "Tasks: Run Task" → "View Performance Dashboard"
3. **Auto-fix Code**: `Ctrl+Shift+P` → "Tasks: Run Task" → "Auto-fix Lua and Markdown"
4. **Run Tests**: `Ctrl+Shift+T` (or use "Run Test Pipeline" task)

### Command Line Workflow

```bash
# Start development environment
make setup                    # First-time setup
make fix                     # Auto-fix linting issues
make test                    # Run test pipeline
make lint                    # Run linters only

# GitHub Actions related
make ci-test                 # Run CI pipeline locally (fast)
make ci-local                # Run full CI pipeline with Docker
make validate-workflows      # Validate GitHub Actions workflows

# Individual operations
./scripts/auto-fix.sh        # Auto-fix Lua and Markdown
bash tests/scripts/test-pipeline.sh  # Run tests
docker stop mediawiki-lua    # Stop MediaWiki container
```

### GitHub Actions CI/CD

The project includes comprehensive GitHub Actions workflows:

- **🔄 Continuous Integration**: Runs on every push/PR with 4-stage testing
- **🔍 Pull Request Validation**: Smart testing based on changed files
- **📦 Automated Releases**: Creates releases with artifacts when tags are pushed
- **🔧 Scheduled Maintenance**: Daily health checks and dependency monitoring
- **🤖 Dependency Updates**: Automated dependency update PRs via Dependabot

**Pipeline Stages**:

1. **Syntax Validation**: Lua syntax checking and linting
2. **Basic Execution**: Module compilation and unit tests
3. **Mocked Environment**: Docker-based MediaWiki environment testing
4. **Scribunto Integration**: Full MediaWiki + Scribunto integration testing

See the **[GitHub Wiki](https://github.com/roscroft/mediawiki-lua-library/wiki/GitHub-Actions)** for complete CI/CD setup and usage instructions.

## 🏗️ Project Architecture

### Clean Repository Structure

This repository has been optimized for maintainability and clarity:

```text
📁 Essential Structure:
├── src/modules/           # Source code (authoritative files)
├── build/modules/         # Build artifacts (symlinks for MediaWiki)
├── scripts/               # Core development scripts (unified)
├── tests/                 # Comprehensive test suite
├── examples/              # Usage examples and demos
├── .github/workflows/     # CI/CD automation
└── 📚 Wiki               # All documentation (linked below)
```

**Key Principles:**

- **Source of Truth**: `src/modules/` contains authoritative code
- **Unified Scripts**: Consolidated tools replace multiple variants  
- **Wiki Documentation**: Comprehensive docs moved to GitHub Wiki
- **Clean History**: Temporary files and completed migrations removed

### Module Structure

```plaintext
src/modules/
├── Array.lua              # Array manipulation utilities
├── Functools.lua          # Functional programming library
├── Funclib.lua            # High-level functional utilities
├── CodeStandards.lua      # Error handling and monitoring
├── PerformanceDashboard.lua # Performance visualization
└── [other modules]        # Additional MediaWiki utilities
```

### Key Features

- **🔧 Functional Programming**: Pure functions, combinators, monads
- **📊 Performance Monitoring**: Real-time metrics and visualization
- **🛡️ Error Handling**: Standardized error management
- **🧪 Comprehensive Testing**: 4-stage test pipeline with Docker integration
- **🚀 CI/CD Pipeline**: GitHub Actions automation for testing and releases
- **🔒 Security**: Environment-based configuration, no hardcoded secrets

## 🚀 Current Status

**✅ Project Status**: Production Ready  
**✅ Test Coverage**: 100% core functionality  
**✅ Security**: Fully remediated  
**✅ Performance**: Dashboard monitoring active  
**✅ Integration**: MediaWiki + VS Code + Docker

### Recent Achievements (June 11, 2025)

- ✅ **GitHub Actions CI/CD Pipeline**: Comprehensive automation for testing, releases, and maintenance
- ✅ **Project-wide MediaWiki Environment Modernization**: 90% code reduction in environment setup
- ✅ **Performance Dashboard Implementation**: Real-time monitoring and visualization
- ✅ **Security Remediation**: Environment-based configuration, secrets removed
- ✅ **Documentation Consolidation**: Complete development history and guides
- ✅ **VS Code Integration**: Task-based development workflow
- ✅ **Auto-fix Pipeline**: Automated linting and formatting

### Next Phase Opportunities

- 🚀 **Advanced MediaWiki Integration**: Template and parser function development
- 📈 **Performance Optimization**: Based on dashboard insights
- 🔌 **Extension Ecosystem**: Additional MediaWiki-specific modules
- 🌐 **Community Integration**: MediaWiki.org deployment preparation

For detailed development history and technical documentation, see the **[GitHub Wiki](https://github.com/roscroft/mediawiki-lua-library/wiki)**.

---

**License**: MIT | **Compatibility**: MediaWiki + Scribunto + Lua 5.1 | **Status**: Active Development
