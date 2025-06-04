# Basic Examples

This directory contains basic examples demonstrating fundamental features of the wiki-lua library.

## Examples

### 1. Array Operations

- Basic array creation and manipulation
- Functional array methods (map, filter, reduce)
- Array utility functions

### 2. Table Operations  

- Table merging and cloning
- Key-value transformations
- Table validation

### 3. String Processing

- Text manipulation utilities
- Template parameter processing
- String validation

### 4. Basic Functional Programming

- Function composition
- Partial application
- Simple higher-order functions

## Running Examples

Each example can be run independently:

```bash
# Run from project root
lua examples/basic/array_operations.lua
```

Or use the test environment:

```bash
# Run in Docker container
docker run -it --rm -v $(pwd):/workspace mediawiki-lua-test test array_operations.lua
```
