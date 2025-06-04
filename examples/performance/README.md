# Performance Examples

This directory contains examples demonstrating performance optimization techniques and benchmarking tools for the MediaWiki Lua functional programming library.

## Examples

### Benchmarking Tools

- `memory_profiler.lua` - Memory usage analysis and profiling
- `execution_timer.lua` - Execution time measurement utilities
- `comparison_benchmarks.lua` - Compare different implementation approaches

### Optimization Patterns

- `lazy_evaluation.lua` - Lazy evaluation techniques for large datasets
- `memoization_examples.lua` - Caching and memoization strategies
- `batch_processing.lua` - Efficient batch processing patterns

## Performance Testing

These examples help you:

1. **Measure Performance**: Time execution and memory usage
2. **Compare Approaches**: Benchmark different algorithms
3. **Optimize Code**: Identify bottlenecks and optimization opportunities
4. **Monitor Production**: Track performance in production environments

## Usage Guidelines

### Benchmarking Best Practices

- Run multiple iterations for accurate measurements
- Test with realistic data sizes
- Consider MediaWiki's memory and execution time limits
- Use the CodeStandards performance monitoring features

### Optimization Strategies

- Use lazy evaluation for large datasets
- Implement memoization for expensive calculations  
- Batch operations when possible
- Prefer immutable operations with functional patterns

## MediaWiki Constraints

Remember MediaWiki's Scribunto limitations:

- Memory limit: typically 50MB
- Execution time limit: typically 10 seconds
- Optimize for these constraints in production code
