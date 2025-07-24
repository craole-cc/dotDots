# High-Performance Directory Path Builder - Implementation Prompt

## Project Overview

Create a high-performance command-line tool that builds colon-separated directory paths from a filesystem tree, with sophisticated filtering and sorting capabilities. This tool should significantly outperform shell script equivalents through compiled language optimizations and efficient algorithms.

## Core Requirements

### Command-Line Interface

Implement a CLI tool with the following arguments:

**Required Arguments:**

- `--target <PATH>` or `-t <PATH>`: Root directory to scan (required)

**Optional Arguments:**

- `--exclude <PATTERN>` or `-e <PATTERN>`: Exclude pattern (repeatable)
- `--ignore-file <PATH>` or `-i <PATH>`: Path to ignore file for additional patterns
- `--sort <TYPE>` or `-s <TYPE>`: Sort method (alphabetical, size, modified, depth, none)
- `--depth <NUM>` or `-d <NUM>`: Maximum recursion depth (0 = unlimited)
- `--help` or `-h`: Display usage information
- `--version` or `-V`: Display version information

### Core Functionality

#### 1. Directory Discovery

- Recursively traverse the target directory tree
- Collect all directories (not files) that meet filtering criteria
- Handle filesystem permissions gracefully (skip inaccessible directories with warnings)
- Support symbolic link handling (follow/don't follow with option)

#### 2. Hierarchical Ignore System

Implement a sophisticated ignore pattern system:

- **Automatic `.ignore` file discovery**: Find and parse all `.ignore` files in the directory tree
- **Hierarchical scope**: Each `.ignore` file affects only directories at or below its location
- **Pattern inheritance**: Child directories inherit patterns from parent `.ignore` files
- **CLI pattern overlay**: Command-line exclude patterns apply globally
- **Ignore file updates**: Optionally append CLI patterns to specified ignore file

**Ignore File Format:**

```sh
# Comments start with #
temp*           # Shell-style wildcards
build/          # Directory-specific patterns
**/.cache       # Recursive patterns
!important/     # Negation patterns (don't ignore)
```

#### 3. Pattern Matching

Support multiple pattern types:

- **Shell wildcards**: `*`, `?`, `[abc]`
- **Recursive patterns**: `**/pattern`
- **Negation patterns**: `!pattern` (override previous excludes)
- **Directory-specific**: `pattern/` (match directories only)

#### 4. Sorting Capabilities

Implement multiple sort methods:

- **alphabetical** (default): Lexicographic order
- **size**: Directory size (including subdirectories)
- **modified**: Last modification time
- **depth**: Directory depth from root (shallow to deep)
- **none**: Filesystem order (fastest)

#### 5. Output Format

- Colon-separated paths suitable for PATH-like variables
- Root directory always included first
- Proper escaping for paths containing spaces or special characters
- Optional output formats (JSON, newline-separated, etc.)

## Performance Requirements

### Efficiency Targets

- Handle directory trees with 100,000+ directories
- Memory usage should scale sub-linearly with tree size
- Startup time under 50ms for typical use cases
- Utilize multiple CPU cores for I/O-bound operations

### Optimization Strategies

- **Parallel directory traversal**: Use thread pools for concurrent I/O
- **Memory-efficient data structures**: Minimize allocations during traversal
- **Smart ignore pattern compilation**: Pre-compile patterns into efficient matchers
- **Early pruning**: Skip entire subtrees when parent directories match exclude patterns
- **Lazy evaluation**: Only compute expensive operations (size, mtime) when needed for sorting

## Technical Specifications

### Error Handling

- Graceful handling of permission denied errors
- Informative error messages with context
- Non-zero exit codes for different error types:
  - 1: General errors
  - 2: Invalid arguments
  - 3: Target directory not found
  - 4: Permission denied

### Cross-Platform Support

- Windows, macOS, Linux compatibility
- Handle platform-specific path separators
- Respect platform-specific ignore patterns (.DS_Store on macOS, Thumbs.db on Windows)

### Configuration

- Support configuration files (.buildir.toml or similar)
- Environment variable overrides
- Reasonable defaults for all options

## Advanced Features

### 1. Depth Control

- `--depth 0`: Only root directory
- `--depth 1`: Root and immediate children
- `--depth N`: Limit recursion to N levels
- Combine with ignore patterns for fine-grained control

### 2. Enhanced Sorting

- **Reverse sorting**: `--sort alphabetical-reverse`
- **Multi-key sorting**: Primary and secondary sort keys
- **Custom sort expressions**: For power users

### 3. Output Customization

- `--output-format`: json, colon, newline, null-separated
- `--relative-paths`: Output paths relative to target
- `--absolute-paths`: Force absolute paths (default)

### 4. Performance Monitoring

- `--stats`: Display performance statistics
- `--verbose`: Detailed operation logging
- `--benchmark`: Time individual operations

### 5. Integration Features

- `--update-ignore`: Append CLI patterns to ignore file
- `--dry-run`: Show what would be excluded without building output
- `--validate-patterns`: Check ignore pattern syntax

## Implementation Guidelines

### Code Quality

- Comprehensive error handling with context
- Extensive unit and integration tests
- Documentation for all public APIs
- Benchmark suite for performance regression detection

### Architecture Suggestions

- **Parser**: Use clap (Rust) or similar for CLI parsing
- **Traversal**: Implement custom walker or use walkdir crate
- **Patterns**: Implement or use glob matching library
- **Parallelism**: Use rayon (Rust) or similar for parallel operations
- **Configuration**: Support TOML/YAML configuration files

### Memory Management

- Use memory pools for frequent allocations
- Implement streaming output for very large result sets
- Profile memory usage under stress conditions

## Testing Requirements

### Unit Tests

- Pattern matching accuracy
- Ignore file parsing
- Sorting algorithms
- Edge cases (empty directories, permission issues)

### Integration Tests

- End-to-end CLI functionality
- Cross-platform behavior
- Performance benchmarks
- Large directory tree handling

### Stress Tests

- Very deep directory trees (1000+ levels)
- Wide directory trees (1000+ siblings)
- Large numbers of ignore patterns
- Memory usage under load

## Documentation Deliverables

### User Documentation

- Comprehensive README with examples
- Man page (Unix) or equivalent help system
- Usage examples for common scenarios
- Performance tuning guide

### Developer Documentation

- Architecture overview
- API documentation
- Contribution guidelines
- Benchmark results and optimization notes

## Example Usage Scenarios

```bash
# Basic usage
buildir --target /usr/local

# With filtering and sorting
buildir -t /project --exclude "test*" --exclude "*.tmp" --sort size

# Depth-limited with custom ignore file
buildir -t /large-project -d 3 -i .buildignore --sort depth

# High-performance mode
buildir -t /huge-tree --sort none --depth 2 --exclude "node_modules"

# Integration with build systems
export BUILD_PATH=$(buildir -t ./build --exclude "cache" --sort modified)
```

## Success Metrics

- 10x+ performance improvement over shell script equivalent
- Memory usage stays under 100MB for trees with 50K+ directories
- Handles edge cases gracefully without crashes
- Clean, maintainable codebase suitable for long-term maintenance
- Comprehensive test coverage (>90%)

This implementation should serve as a foundation for a production-ready tool that can be integrated into build systems, development workflows, and automation scripts where performance and reliability are critical.
