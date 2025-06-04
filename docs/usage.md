# Wiki Lua Testing Guide

## Overview

This guide documents the comprehensive testing pipeline for MediaWiki Lua modules with multiple verification stages. Our framework provides methods to test modules at different levels - from basic syntax checking to full MediaWiki integration.

## Mock Environment

Our testing framework provides a mock environment (wiki-lua-env.lua) that simulates MediaWiki's Lua interface:

```lua
-- Access HTML building functionality
local div = mw.html.create('div')
  :addClass('content')
  :attr('id', 'main')
  :wikitext('Hello world!')

-- Use text utilities
local trimmed = mw.text.trim('  some text  ')
local parts = mw.text.split('a,b,c', ',')
local json = mw.text.jsonEncode({key = "value"})

-- Parameter validation with libraryUtil
libraryUtil.checkType('myFunction', 1, param, 'string')
libraryUtil.checkTypeMulti('myFunction', 2, param, 'string', 'number')
```

## Testing Methods

### 1. Syntax Checking with Luacheck

```bash
# Install luacheck (one-time setup)
luarocks install --local luacheck

# Create .luacheckrc configuration
cat > .luacheckrc << 'EOF'
std = "lua51"
globals = {
    "mw",
    "libraryUtil"
}
ignore = {"611", "612"}  -- Ignore line length warnings
EOF

# Check a specific module
luacheck src/modules/Funclib.lua

# Check all modules
luacheck src/modules/*.lua
```

### 2. Basic Lua Execution

Test that your module loads without MediaWiki dependencies:

```bash
# Test a specific module
docker run --rm -v $(pwd)/src/modules/Funclib.lua:/test.lua alpine:latest \
  sh -c "apk add --no-cache lua5.1 && lua /test.lua"
```

### 3. Mocked Environment Testing

Test with our mock environment that provides mw.* and libraryUtil:

```bash
# Build the Docker image (if not already built)
docker build -t wiki-lua-env .

# Test a module with the mocked environment
docker run --rm -v $(pwd)/src:/var/www/html/src \
  -v $(pwd)/build:/var/www/html/build \
  wiki-lua-env test "Module:Funclib"

# Using the test pipeline (recommended)
./tests/scripts/test-pipeline.sh
```

### 4. Real Scribunto Testing

Test with actual MediaWiki and Scribunto (full integration testing):

```bash
# Test with real MediaWiki/Scribunto
docker run --rm -v $(pwd)/src:/var/www/html/src \
  -v $(pwd)/build:/var/www/html/build \
  wiki-lua-env real-test "Module:Funclib"
```

### 5. Complete Testing Pipeline

Run all test stages in sequence:

```bash
# Test all stages for all modules
./tests/scripts/test-pipeline.sh

# Run only syntax checking
luacheck src/modules/*.lua

# Run only mocked environment tests
docker run --rm -v $(pwd)/src:/var/www/html/src wiki-lua-env

# Test all modules individually
for module in src/modules/*.lua; do
  echo "Testing $(basename $module)"
  luacheck "$module"
done
```

## Example Test Output

```text
=================================================
=== Testing Pipeline for: funclib.lua
=================================================

[Stage 1] Lua Syntax Check
Running luacheck...
✓ Syntax check passed

[Stage 2] Basic Lua Execution
Running Lua without MediaWiki dependencies...
✓ Lua execution passed

[Stage 3] Mocked Wiki Environment
Running with mocked mw and libraryUtil...
Testing module: funclib.lua
Wiki Lua test environment initialized
Registered Array → /var/www/html/modules/custom/Array.lua
Loading module: Module:Array from /var/www/html/modules/custom/Array.lua
Module loaded successfully!

Module exports 18 functions/values:
  - VERSION: string
  - FORMAT: table
  - DEFAULTS: table
  - TableBuilder: table
  - isArray: function
  - indexOf: function
  - contains: function
  - extend: function
  - filter: function
  - map: function
  - shuffle: function
  - unique: function
  - collect: function
  - concat: function
  - join: function
  - split: function
  - merge: function
  - slice: function
✓ Mocked environment test passed

[Stage 4] Real Scribunto Environment
Running with real MediaWiki and Scribunto...
Testing with real Scribunto: funclib.lua
Module loaded successfully!
Functions available: 18
  - VERSION: string
  - FORMAT: array
  - DEFAULTS: array
  - TableBuilder: array
  - isArray: object
  - indexOf: object
  - contains: object
  - extend: object
  - filter: object
  - map: object
  - shuffle: object
  - unique: object
  - collect: object
  - concat: object
  - join: object
  - split: object
  - merge: object
  - slice: object
✓ Real Scribunto test passed

=================================================
All requested tests passed for: funclib.lua
=================================================
```

## Advanced Use Cases

### Testing Modules with Dependencies

For modules that require other modules, our system automatically resolves MediaWiki-style dependencies:

```lua
-- In your module:
local Array = require('Module:Array')

-- This will work in both mocked and real environment tests
```

### Adding Custom Mock Functions

To extend the mock environment, add your functions to wiki-lua-env.lua:

```lua
-- Add custom functionality
mw.myCustomLib = {
    doSomething = function(param)
        return "Processed: " .. param
    end
}
```

### Debugging Failed Tests

If a test fails, examine the specific stage output for details:

```bash
# Run with verbose output
docker run --rm -v $(pwd)/lists/library:/var/www/html/modules/custom \
  wiki-lua-env test "problematic-module.lua" 2>&1 | tee debug.log
```

## Docker Aliases

For convenience, add these aliases to your `.bashrc`:

```bash
# Wiki Lua Docker Aliases (Legacy - use test pipeline instead)
alias wl-build="docker build -t wiki-lua-env ."
alias wl-server="docker run -d --name wiki-lua -p 8080:80 -v $(pwd)/src:/var/www/html/src -v $(pwd)/build:/var/www/html/build wiki-lua-env"
alias wl-test="./tests/scripts/test-pipeline.sh"
alias wl-stop="docker stop wiki-lua"
alias wl-rm="docker rm wiki-lua"
alias wl-restart="wl-stop && wl-rm && wl-server" 
alias wl-logs="docker logs -f wiki-lua"
alias wl-shell="docker exec -it wiki-lua bash"
```

This comprehensive testing approach ensures your Wiki Lua modules work correctly at every level - from basic syntax to full MediaWiki integration.

## Running the Wiki Lua Testing Pipeline

The Wiki Lua project provides a comprehensive testing environment for MediaWiki Lua modules using Docker. Here's how to run the complete testing pipeline:

## Step 1: Project Setup

First, ensure all required files are in place:

```bash
# Clone the repository if you haven't already
git clone https://github.com/yourusername/wiki-lua.git
cd wiki-lua

# Create necessary directories if they don't exist
mkdir -p src/modules
```

## Step 2: Create Required Files

Make sure these essential files exist:

1. **Dockerfile** - Defines the MediaWiki container
2. **LocalSettings.php** - MediaWiki configuration
3. **entrypoint.sh** - Container startup script
4. **wiki-lua-env.lua** - Mock environment
5. **test-script-simple.php** - Testing script
6. **test-pipeline.sh** - Pipeline orchestration script

## Step 3: Build the Docker Image

```bash
# Build the Docker image
docker build -t wiki-lua-env .
```

## Step 4: Run the Pipeline

For a single module:

```bash
# To run all test stages on a specific module
./test-pipeline.sh funclib.lua

# Alternatively, with the convenience script we created
./test-module.sh funclib.lua
```

For multiple modules:

```bash
# Test all modules in your library
for module in src/modules/*.lua; do
  echo "Testing $(basename $module)"
  luacheck "$module"
done
```

## Step 5: Testing Stages

The pipeline runs these stages in sequence:

1. **Stage 1**: Luacheck syntax validation
2. **Stage 2**: Plain Lua execution (without MediaWiki)
3. **Stage 3**: Mocked MediaWiki environment
4. **Stage 4**: Real Scribunto/MediaWiki integration

You can also run specific stages:

```bash
# Run only syntax checking
./test-pipeline.sh funclib.lua --syntax

# Run only mocked environment tests
./test-pipeline.sh funclib.lua --mock

# Run only real Scribunto tests 
./test-pipeline.sh funclib.lua --real
```

## Using Docker Aliases

If you've added the aliases to your `.bashrc`:

```bash
# Source your .bashrc to make aliases available
source ~/.bashrc

# Test a specific module
wl-test "funclib.lua"

# Start the MediaWiki server
wl-server

# Get a shell in the container
wl-shell
```

## Troubleshooting

If you encounter issues:

1. Make sure Docker is running
2. Verify all required files are in place
3. Check module dependencies
4. Run the tests with verbose output:

```bash
./test-pipeline.sh funclib.lua 2>&1 | tee debug.log
```

The pipeline will generate color-coded output showing the progress and results of each testing stage, making it easy to identify any issues with your Lua modules.
