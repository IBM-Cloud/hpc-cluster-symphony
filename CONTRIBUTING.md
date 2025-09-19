# Contributing to IBM HPC Cluster Symphony

Thank you for your interest in contributing to the IBM HPC Cluster Symphony project! This document provides guidelines and information for contributors.

## 🚀 Getting Started

### Prerequisites

- **Terraform** >= 1.5.0
- **Python** >= 3.8
- **IBM Cloud CLI** with VPC plugin
- **Git**
- **Make** (optional, for using Makefile commands)

### Development Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/IBM/hpc-cluster-symphony.git
   cd hpc-cluster-symphony
   ```

2. **Create a new branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Install dependencies**
   ```bash
   make install
   # or manually:
   pip install -r requirements.txt
   pre-commit install
   ```

4. **Set up environment variables**
   ```bash
   export IBM_CLOUD_API_KEY="your-api-key"
   export TF_VAR_api_key="your-api-key"
   ```

## 📋 Development Workflow

### 1. Code Quality Standards

We maintain high code quality standards using automated tools:

#### Python Code
- **Formatting**: Black (line length: 88)
- **Import sorting**: isort
- **Linting**: pylint, flake8
- **Type checking**: mypy
- **Security**: bandit

#### Terraform Code
- **Formatting**: `terraform fmt`
- **Linting**: TFLint
- **Security**: Checkov, Terrascan
- **Validation**: `terraform validate`

### 2. Running Quality Checks

```bash
# Format all code
make format

# Run all linting
make lint

# Run security scans
make security

# Run all checks
make all
```

### 3. Testing Requirements

All contributions must include appropriate tests:

#### Unit Tests
- **Location**: `tests/unit/`
- **Coverage**: Minimum 80% code coverage
- **Framework**: pytest

```bash
# Run unit tests
pytest tests/unit/ -v --cov=resources

# Run specific test file
pytest tests/unit/test_remove_security_rule.py -v
```

#### Integration Tests
- **Location**: `tests/integration/`
- **Purpose**: Test Terraform deployments with real IBM Cloud resources
- **Requirements**: Valid IBM Cloud API key

```bash
# Run integration tests (requires IBM Cloud credentials)
pytest tests/integration/ -v -m integration
```

### 4. Pre-commit Hooks

We use pre-commit hooks to ensure code quality:

```bash
# Install hooks
pre-commit install

# Run hooks manually
pre-commit run --all-files
```

## 🧪 Testing Guidelines

### Writing Unit Tests

1. **Test file naming**: `test_<module_name>.py`
2. **Test class naming**: `TestClassName`
3. **Test method naming**: `test_method_description`
4. **Use fixtures**: Leverage pytest fixtures for common setup
5. **Mock external dependencies**: Use `unittest.mock` for external APIs

Example:
```python
import pytest
from unittest.mock import Mock, patch

class TestRemoveSecurityRule:
    def test_get_access_token_success(self, mock_ibm_cloud_api, sample_api_key):
        """Test successful token retrieval."""
        result = get_access_token(sample_api_key)
        assert result["access_token"] == "mock_access_token"
```

### Writing Integration Tests

1. **Mark with pytest markers**: `@pytest.mark.integration`
2. **Include cleanup**: Always clean up created resources
3. **Use unique names**: Generate unique resource names to avoid conflicts
4. **Test timeouts**: Set appropriate timeouts for long-running operations

Example:
```python
@pytest.mark.integration
@pytest.mark.slow
def test_terraform_deployment(terraform_helper, test_tfvars_file):
    """Test actual Terraform deployment."""
    # Test implementation
```

## 🔒 Security Guidelines

### Secrets Management
- **Never commit secrets**: Use environment variables or secure vaults
- **Use .gitignore**: Ensure sensitive files are ignored
- **Scan for secrets**: Use detect-secrets and bandit

### Terraform Security
- **Follow best practices**: Use least privilege principles
- **Validate configurations**: Run Checkov and Terrascan
- **Review security groups**: Ensure minimal required access

### Python Security
- **Dependency scanning**: Use safety to check for vulnerabilities
- **Code scanning**: Use bandit for security issues
- **Input validation**: Always validate and sanitize inputs

## 📝 Documentation Standards

### Code Documentation
- **Docstrings**: All functions and classes must have docstrings
- **Type hints**: Use type hints for function parameters and returns
- **Comments**: Explain complex logic and business rules

### Terraform Documentation
- **Variable descriptions**: All variables must have descriptions
- **Output descriptions**: All outputs must have descriptions
- **Module documentation**: Include README.md for complex modules

## 🔄 Pull Request Process

### Before Submitting

1. **Run all tests**
   ```bash
   make test
   ```

2. **Run quality checks**
   ```bash
   make lint
   make security
   ```

3. **Update documentation** if needed

4. **Add tests** for new functionality

### PR Requirements

- [ ] All tests pass
- [ ] Code coverage >= 80%
- [ ] Security scans pass
- [ ] Documentation updated
- [ ] Commit messages follow conventional format
- [ ] PR description explains changes

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing completed

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] Tests added and passing
```

## 🏗️ Architecture Guidelines

### Terraform Structure
- **Modular design**: Use modules for reusable components
- **Variable validation**: Add validation rules for inputs
- **Output consistency**: Provide consistent and useful outputs
- **Resource naming**: Use consistent naming conventions

### Python Structure
- **Single responsibility**: Each function should have one purpose
- **Error handling**: Implement proper error handling and logging
- **Configuration**: Use environment variables for configuration
- **Logging**: Include appropriate logging for debugging

## 🐛 Reporting Issues

### Bug Reports
Include:
- **Environment details**: OS, Terraform version, Python version
- **Steps to reproduce**: Clear reproduction steps
- **Expected vs actual behavior**
- **Logs and error messages**
- **Configuration files** (sanitized)

### Feature Requests
Include:
- **Use case description**: Why is this needed?
- **Proposed solution**: How should it work?
- **Alternatives considered**: Other approaches evaluated
- **Additional context**: Any other relevant information

## 📞 Getting Help

- **GitHub Issues**: For bugs and feature requests
- **GitHub Discussions**: For questions and general discussion
- **IBM Cloud Documentation**: For IBM Cloud specific questions

## 🎯 Code Review Guidelines

### For Reviewers
- **Be constructive**: Provide helpful feedback
- **Check tests**: Ensure adequate test coverage
- **Verify security**: Look for security issues
- **Test locally**: Test changes when possible

### For Contributors
- **Respond promptly**: Address review comments quickly
- **Explain decisions**: Justify design choices
- **Update tests**: Modify tests based on feedback
- **Be patient**: Reviews take time

## 📊 Metrics and Quality Gates

### Quality Metrics
- **Code coverage**: >= 80%
- **Security scan**: No high/critical issues
- **Linting**: No errors or warnings
- **Tests**: All tests must pass

### Performance Metrics
- **Terraform plan time**: < 5 minutes
- **Terraform apply time**: < 30 minutes (for basic deployment)
- **Test execution time**: < 10 minutes (unit tests)

## 🏆 Recognition

Contributors will be recognized in:
- **CONTRIBUTORS.md**: List of all contributors
- **Release notes**: Major contributions highlighted
- **GitHub**: Contributor badges and statistics

Thank you for contributing to IBM HPC Cluster Symphony! 🚀
