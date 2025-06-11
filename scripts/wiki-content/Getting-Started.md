# Getting Started

This guide will help you set up and start using the MediaWiki Lua Module Library.

## Prerequisites

**Required:**
- **Docker** (for MediaWiki development environment)
- **Git** (for version control)

**Optional but Recommended:**
- **VS Code** (enhanced development experience)
- **Node.js & npm** (for markdown formatting tools)
- **Lua 5.1** and **luacheck** (for local Lua development)

## Installation

### 1. Clone Repository

```bash
git clone https://github.com/roscroft/mediawiki-lua-library.git
cd mediawiki-lua-library
```

### 2. Security Configuration

```bash
# Copy environment template
cp .env.template .env

# Generate secure keys (Linux/Mac)
openssl rand -hex 32  # Use for MEDIAWIKI_SECRET_KEY
openssl rand -hex 16  # Use for MEDIAWIKI_UPGRADE_KEY

# Edit .env file and update passwords and keys
```

### 3. Start Development Environment

```bash
# Option A: Using VS Code Tasks (Recommended)
# Open VS Code → Ctrl+Shift+P → "Tasks: Run Task" → "Start MediaWiki Container"

# Option B: Using Scripts  
./scripts/start-mediawiki.sh

# Option C: Manual Docker
docker run -d --name mediawiki-lua \
  -p 8080:80 \
  -v $(pwd)/src/modules:/var/www/html/extensions/Scribunto/includes/engines/LuaStandalone/lualib \
  --env-file .env \
  mediawiki:latest
```

### 4. Verify Installation

```bash
# Run test pipeline
bash tests/scripts/test-pipeline.sh

# Expected: All 4 stages should pass
```

## Access Points

- **MediaWiki Interface**: http://localhost:8080
- **Performance Dashboard**: Use VS Code task "View Performance Dashboard"
- **Module Testing**: `bash tests/scripts/test-pipeline.sh`

## Next Steps

- **[Development Guide](Development-Guide)** - Learn development patterns
- **[Testing](Testing)** - Understand the testing framework
- **[Security](Security)** - Review security guidelines

For detailed usage instructions, see the main [Home](Home) page.
