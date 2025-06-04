# Integration Examples

This directory contains examples showing how to integrate the MediaWiki Lua functional programming library with MediaWiki-specific features and workflows.

## Examples

### MediaWiki Template Integration

- `template_integration.lua` - Shows how to use the library within MediaWiki templates
- `scribunto_module.lua` - Complete Scribunto module example using the library

### Wiki Content Processing

- `wiki_content_processor.lua` - Process and transform wiki content using functional patterns
- `category_analyzer.lua` - Analyze and organize wiki categories functionally

### Performance in Production

- `production_optimization.lua` - Production-ready optimizations and best practices

## Usage in MediaWiki

These examples are designed to be used within MediaWiki's Scribunto environment. To use:

1. Create a new module page in your wiki (e.g., "Module:ExampleName")
2. Copy the example code into the module
3. Invoke the module from templates or other pages

## Module Dependencies

These examples assume you have the core functional programming modules available:

- `Array`
- `Functools`
- `TableTools`
- `CodeStandards`
- `AdvancedFunctional`

## Best Practices

- Always use error handling with `CodeStandards.handleError()`
- Implement performance monitoring for production modules
- Use immutable operations where possible
- Follow MediaWiki naming conventions for module functions
