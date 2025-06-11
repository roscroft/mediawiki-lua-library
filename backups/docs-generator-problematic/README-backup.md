# Lua Documentation Generator

A standalone, configurable documentation generator for Lua modules, specifically designed for MediaWiki Scribunto modules.

## Features

- **Multiple Output Formats**: HTML, Markdown, and more
- **Configurable Styles**: Elegant, functional, refactored, and ultimate styles
- **JSDoc-Style Comments**: Parses JSDoc-style documentation comments
- **MediaWiki Integration**: Designed for Scribunto module documentation
- **Standalone Operation**: Can be used as a submodule or standalone tool
- **Template-Based**: Customizable output templates

## Installation

### As a Submodule (Recommended)

```bash
# Add as submodule to your project
git submodule add https://github.com/roscroft/lua-docs-generator.git tools/docs-generator
git submodule update --init --recursive
```

### Standalone Installation

```bash
git clone https://github.com/roscroft/lua-docs-generator.git
cd lua-docs-generator
```

## Usage

### Basic Usage

```bash
# Generate documentation for all modules
lua bin/generate-docs.lua --source=/path/to/modules --output=/path/to/docs

# Generate for specific module
lua bin/generate-docs.lua --source=/path/to/modules --output=/path/to/docs ModuleName

# Use specific style
lua bin/generate-docs.lua --style=elegant --source=/path/to/modules --output=/path/to/docs
```

### Advanced Usage

```bash
# Generate both HTML and Markdown
lua bin/generate-docs.lua --format=both --source=/path/to/modules --output=/path/to/docs

# Verbose output
lua bin/generate-docs.lua --verbose --source=/path/to/modules --output=/path/to/docs

# Custom configuration
lua bin/generate-docs.lua --config=custom-config.lua --source=/path/to/modules --output=/path/to/docs
```

### Integration with MediaWiki Projects

```bash
# From your MediaWiki Lua project root
tools/docs-generator/bin/generate-docs.lua --source=src/modules --output=docs
```

## Configuration

### Command Line Options

- `--source=<dir>` - Source directory containing Lua modules
- `--output=<dir>` - Output directory for generated documentation
- `--style=<style>` - Documentation style (elegant, functional, refactored, ultimate)
- `--format=<format>` - Output format (html, markdown, both)
- `--config=<file>` - Custom configuration file
- `--verbose` - Enable verbose output
- `--help` - Show help message

### Configuration File

Create a `docs-config.lua` file for custom settings:

```lua
return {
    style = "elegant",
    format = "html",
    templates = {
        html = "templates/custom.html",
        markdown = "templates/custom.md"
    },
    parsing = {
        extractFunctions = true,
        extractTypes = true,
        extractExamples = true
    }
}
```

## Supported Documentation Formats

### JSDoc-Style Comments

```lua
--[[
Module description here.

@param param1 string Description of parameter
@param param2 number Optional parameter
@return string Description of return value
@example
local result = myFunction("test", 42)
print(result)
]]
function myFunction(param1, param2)
    -- Implementation
end
```

## Output Styles

- **Elegant**: Clean, minimalist documentation
- **Functional**: Emphasizes functional programming patterns
- **Refactored**: Structured, modular documentation
- **Ultimate**: Comprehensive documentation with advanced features

## Development

### Project Structure

```
lua-docs-generator/
├── bin/                    # Main executable scripts
├── lib/                    # Core library modules
├── templates/              # Output templates
├── config/                 # Configuration files
├── tests/                  # Test suite
├── examples/               # Usage examples
└── docs/                   # Documentation
```

### Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

MIT License - see LICENSE file for details.

## Changelog

### v1.0.0 (Initial Release)

- Basic HTML and Markdown generation
- Multiple style support
- JSDoc comment parsing
- MediaWiki integration
- Submodule support
