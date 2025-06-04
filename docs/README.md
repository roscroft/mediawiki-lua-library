# MediaWiki Lua Project Documentation

Welcome to the comprehensive documentation for the MediaWiki Lua Project - an advanced functional programming ecosystem designed for MediaWiki environments.

## 📚 Documentation Index

### Core Documentation

- **[README.md](../README.md)** - Main project overview and quick start guide
- **[Development History](development-history.md)** - Complete chronological development timeline
- **[Project Status](PROJECT_STATUS.md)** - Current project status and module information
- **[Usage Guide](usage.md)** - Comprehensive testing and usage instructions
- **[Testing Guide](testing.md)** - Testing infrastructure and procedures

### Security Documentation

- **[Security Guide](SECURITY.md)** - Security setup and best practices
- **[Security Remediation](SECURITY_REMEDIATION_COMPLETE.md)** - Complete security remediation report

### Performance & Monitoring

- **[Performance Dashboard Status](PERFORMANCE_DASHBOARD_STATUS.md)** - Performance monitoring system status

### API Documentation

- **[API Documentation](api/)** - Module-specific API documentation
  - [Array Documentation](api/Array-doc.txt) - Array module API reference

## 🚀 Quick Start

1. **Read the [README.md](../README.md)** for project overview
2. **Review [Security Guide](SECURITY.md)** for secure setup
3. **Follow [Usage Guide](usage.md)** for testing and development
4. **Check [Development History](development-history.md)** for project evolution

## 🏗️ Project Architecture

The MediaWiki Lua Project consists of:

### Core Modules (`src/modules/`)

- **CodeStandards.lua** - Standardized error handling and performance monitoring
- **Array.lua** - High-performance array operations
- **Functools.lua** - Pure functional programming utilities
- **Funclib.lua** - MediaWiki UI components and table builders
- **TableTools.lua** - Advanced table manipulation and analysis
- **PerformanceDashboard.lua** - Performance monitoring and visualization

### Supporting Libraries

- **Arguments.lua** - Argument processing utilities
- **Paramtest.lua** - Parameter validation and testing
- **Clean_image.lua** - Image processing utilities
- **Lists.lua** - High-level list creation interface

### Data Modules (`src/data/`)

- **abilitylist.lua** - Ability data structures
- **prayerlist.lua** - Prayer data structures
- **shoplist.lua** - Shop data structures
- **spelllist.lua** - Spell data structures

## 🧪 Testing Infrastructure

### Testing Pipeline

The project includes a comprehensive 4-stage testing pipeline:

1. **Syntax Validation** - Lua syntax checking
2. **Basic Execution** - Module compilation testing
3. **Mocked Environment** - Simulated MediaWiki testing
4. **Scribunto Integration** - Full MediaWiki container testing

### Test Categories

- **Unit Tests** (`tests/unit/`) - Individual module testing
- **Integration Tests** (`tests/integration/`) - Cross-module functionality
- **Production Tests** (`tests/`) - Real-world scenario testing

## 🔧 Development Tools

### VS Code Integration

- **Start MediaWiki Container** - One-click environment setup
- **View Performance Dashboard** - Performance monitoring visualization
- **Browser Integration** - Direct MediaWiki and dashboard access

### Scripts (`scripts/`)

- **start-mediawiki.sh** - MediaWiki container initialization
- **view-dashboard.sh** - Performance dashboard generation
- **setup.sh** - Development environment setup
- **cleanup.sh** - Development environment cleanup

## 📊 Current Status

**Project Phase**: Production Ready ✅  
**Integration Status**: 100% Complete  
**Test Success Rate**: 100%  
**Security Status**: Fully Remediated  
**CodeStandards Integration**: Complete across all core modules

## 🔒 Security Features

- **Environment Variable Configuration** - No hardcoded credentials
- **Secure Template System** - `.env.template` and `LocalSettings.template.php`
- **Comprehensive .gitignore** - Prevents accidental secret commits
- **Security Documentation** - Complete setup and deployment guides

## 📈 Performance Monitoring

The project includes comprehensive performance monitoring:

- **Real-time Tracking** - All enhanced functions monitored
- **Performance Dashboard** - Visual performance analysis
- **Optimization Insights** - Data-driven optimization recommendations
- **Error Tracking** - Standardized error handling and logging

## 🤝 Contributing

To contribute to the project:

1. Review the [Development History](development-history.md) to understand project evolution
2. Follow the [Security Guide](SECURITY.md) for secure development practices
3. Use the [Testing Guide](testing.md) to verify your changes
4. Ensure all tests pass before submitting changes

## 📞 Support

For questions or issues:

1. Check the [Usage Guide](usage.md) for common scenarios
2. Review the [API Documentation](api/) for specific module usage
3. Consult the [Development History](development-history.md) for implementation details
4. Check the [Project Status](PROJECT_STATUS.md) for current capabilities

---

_Last Updated: June 4, 2025_  
_MediaWiki Lua Project - Advanced Functional Programming Ecosystem_
