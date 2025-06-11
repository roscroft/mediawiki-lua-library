# MediaWiki Lua Documentation Generator

A standalone documentation generator specifically designed for MediaWiki Lua modules. This repository contains the extracted and enhanced documentation generation functionality from the [MediaWiki Lua Library](https://github.com/roscroft/mediawiki-lua-library) project.

## Overview

This tool generates comprehensive HTML and Markdown documentation for MediaWiki Lua modules by parsing JSDoc-style comments and function definitions. It's specifically optimized for MediaWiki/Scribunto environments and includes specialized parsers for MediaWiki module patterns.

## Features

- **MediaWiki-Specific**: Designed for MediaWiki Lua modules and Scribunto environment
- **Multiple Styles**: Elegant, functional, refactored, and ultimate documentation styles
- **Dual Generators**: Unified generator with multiple styles, and lightweight simple generator
- **JSDoc Support**: Parses JSDoc-style comments with MediaWiki-specific extensions
- **Multiple Formats**: HTML and Markdown output formats
- **Function Detection**: Sophisticated parsing of MediaWiki module function patterns
- **Type Analysis**: Advanced type parsing for Lua and MediaWiki types
- **Template Engine**: Flexible templating system for customizable output

## Quick Start

### Basic Usage

```bash
# Generate documentation for all modules
lua bin/generate-docs.lua

# Generate documentation for a specific module
lua bin/generate-docs.lua Array

# Generate with elegant style
lua bin/generate-docs.lua --style=elegant

# Generate using simple generator
lua bin/generate-docs.lua --generator=simple
```

### Configuration

```bash
# Custom source and output directories
lua bin/generate-docs.lua --source=../modules --output=../docs

# Multiple formats
lua bin/generate-docs.lua --format=both

# Verbose output
lua bin/generate-docs.lua --verbose
```

## MediaWiki Module Support

This generator is specifically designed for MediaWiki Lua modules and includes:

### Function Pattern Detection
```lua
-- Supports various MediaWiki module patterns:
function p.myFunction(frame)  -- Standard MediaWiki function
p.myFunction = function(frame)  -- Assignment pattern
local function helper()  -- Local functions (private)
Module.utilities.func = function()  -- Nested module functions
```

### JSDoc Comments
```lua
--[[
 * Function description
 * @param {frame} frame MediaWiki frame object
 * @param {string} param1 Description of parameter
 * @returns {string} Description of return value
 * @example
 * local result = p.myFunction(frame)
]]
```

## Command Line Options

```
Usage: lua bin/generate-docs.lua [options] [module_name]

Options:
  --style=STYLE         Documentation style: elegant, functional, refactored, ultimate
  --generator=TYPE      Generator type: unified, simple (default: unified)
  --source=DIR          Source directory (default: src/modules)
  --output=DIR          Output directory (default: src/module-docs)
  --format=FORMAT       Output format: html, markdown, both (default: html)
  --verbose             Verbose output
  --help, -h            Show this help
  --version             Show version
```

## Integration

This generator is designed to be used as a submodule in MediaWiki Lua projects:

```bash
# Add as submodule
git submodule add https://github.com/your-org/mediawiki-lua-docs-generator tools/docs-generator

# Generate documentation
cd tools/docs-generator
lua bin/generate-docs.lua --source=../../src/modules --output=../../docs
```

## License

This project is licensed under the same terms as the parent MediaWiki Lua Library project.
