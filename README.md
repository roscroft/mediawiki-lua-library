# MediaWiki Lua Module Library

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

Complete documentation is available in the [`docs/`](docs/) directory:

- **[Usage Guide](docs/usage.md)** - Testing and usage instructions
- **[Development History](docs/development-history.md)** - Complete project timeline
- **[Security Setup](docs/SECURITY.md)** - Security configuration and best practices
- **[Testing Documentation](docs/testing.md)** - Testing infrastructure details
- **[Project Status](docs/PROJECT_STATUS.md)** - Current module status and features

## 🛠️ Development Workflow

### VS Code Integration (Recommended)

1. **Start MediaWiki**: `Ctrl+Shift+P` → "Tasks: Run Task" → "Start MediaWiki Container & Open Browser"
2. **View Dashboard**: `Ctrl+Shift+P` → "Tasks: Run Task" → "View Performance Dashboard"
3. **Auto-fix Code**: `Ctrl+Shift+P` → "Tasks: Run Task" → "Auto-fix Lua and Markdown"

### Command Line Workflow

```bash
# Start development environment
make setup                    # First-time setup
make fix                     # Auto-fix linting issues
make test                    # Run test pipeline
make lint                    # Run linters only

# Individual operations
./scripts/auto-fix.sh        # Auto-fix Lua and Markdown
bash tests/scripts/test-pipeline.sh  # Run tests
docker stop mediawiki-lua    # Stop MediaWiki container
```

## 🏗️ Project Architecture

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
- **🔒 Security**: Environment-based configuration, no hardcoded secrets

## 🚀 Current Status

**✅ Project Status**: Production Ready  
**✅ Test Coverage**: 100% core functionality  
**✅ Security**: Fully remediated  
**✅ Performance**: Dashboard monitoring active  
**✅ Integration**: MediaWiki + VS Code + Docker

### Recent Achievements (June 4, 2025)

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

For detailed development history and technical documentation, see the [`docs/`](docs/) directory.

---

**License**: MIT | **Compatibility**: MediaWiki + Scribunto + Lua 5.1 | **Status**: Active Development
