# Testing Infrastructure for IBM HPC Cluster Symphony

This document provides comprehensive information about the testing infrastructure implemented for the IBM HPC Cluster Symphony project.

## 🧪 Testing Overview

Our testing strategy follows a multi-layered approach to ensure code quality, security, and reliability:

1. **Unit Tests** - Test individual functions and components
2. **Integration Tests** - Test interactions between components and with IBM Cloud
3. **Security Tests** - Scan for vulnerabilities and security issues
4. **Code Quality Tests** - Ensure code formatting and standards
5. **Infrastructure Tests** - Validate Terraform configurations

## 📁 Test Structure

```
tests/
├── __init__.py                 # Test package initialization
├── conftest.py                 # Shared pytest fixtures
├── unit/                       # Unit tests
│   ├── __init__.py
│   ├── test_remove_security_rule.py
│   └── test_*.py              # Additional unit tests
└── integration/                # Integration tests
    ├── __init__.py
    ├── test_terraform_deployment.py
    └── test_*.py              # Additional integration tests
```

## 🚀 Quick Start

### Prerequisites

1. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

2. **Set up environment variables**:
   ```bash
   export IBM_CLOUD_API_KEY="your-api-key"
   export TF_VAR_api_key="your-api-key"
   export TEST_SSH_KEY_NAME="your-test-ssh-key"
   export IBM_CUSTOMER_NUMBER="your-customer-number"
   ```

### Running Tests

#### Unit Tests Only
```bash
# Run all unit tests
pytest tests/unit/ -v

# Run with coverage
pytest tests/unit/ -v --cov=resources --cov-report=html

# Run specific test file
pytest tests/unit/test_remove_security_rule.py -v

# Run specific test method
pytest tests/unit/test_remove_security_rule.py::TestGetAccessToken::test_get_access_token_success -v
```

#### Integration Tests
```bash
# Run integration tests (requires IBM Cloud credentials)
pytest tests/integration/ -v -m integration

# Run integration tests with cleanup
pytest tests/integration/ -v -m integration --tb=short

# Skip slow tests
pytest tests/integration/ -v -m "integration and not slow"
```

#### All Tests
```bash
# Run all tests
pytest tests/ -v

# Run with coverage and generate HTML report
pytest tests/ -v --cov=resources --cov-report=html --cov-report=term
```

## 🔧 Test Configuration

### Pytest Configuration

The project uses `pyproject.toml` for pytest configuration:

```toml
[tool.pytest.ini_options]
minversion = "6.0"
addopts = "-ra -q --strict-markers --strict-config"
testpaths = ["tests"]
markers = [
    "slow: marks tests as slow (deselect with '-m \"not slow\"')",
    "integration: marks tests as integration tests",
    "unit: marks tests as unit tests",
]
```

### Test Markers

- `@pytest.mark.unit` - Unit tests (fast, no external dependencies)
- `@pytest.mark.integration` - Integration tests (require IBM Cloud)
- `@pytest.mark.slow` - Slow-running tests (> 30 seconds)

### Fixtures

Common fixtures are defined in `tests/conftest.py`:

- `mock_ibm_cloud_api` - Mock IBM Cloud API responses
- `sample_api_key` - Sample API key for testing
- `sample_security_group_data` - Sample security group data
- `temp_terraform_dir` - Temporary directory with Terraform files
- `integration_config` - Configuration for integration tests

## 📊 Coverage Requirements

- **Minimum coverage**: 80%
- **Coverage reports**: Generated in HTML and XML formats
- **Coverage exclusions**: Test files, `__pycache__`, and generated files

### Viewing Coverage Reports

```bash
# Generate HTML coverage report
pytest tests/unit/ --cov=resources --cov-report=html

# Open coverage report
open htmlcov/index.html  # macOS
xdg-open htmlcov/index.html  # Linux
start htmlcov/index.html  # Windows
```

## 🧪 Unit Testing Guidelines

### Test Structure

```python
"""
Unit tests for module_name.py
"""

import pytest
from unittest.mock import Mock, patch

class TestClassName:
    """Test cases for ClassName."""
    
    def test_method_success(self, fixture_name):
        """Test successful method execution."""
        # Arrange
        # Act
        # Assert
    
    def test_method_error_handling(self):
        """Test error handling."""
        # Test implementation
```

### Best Practices

1. **Use descriptive test names**: `test_get_access_token_success`
2. **Follow AAA pattern**: Arrange, Act, Assert
3. **Mock external dependencies**: Use `unittest.mock`
4. **Test edge cases**: Empty inputs, invalid data, network errors
5. **Use fixtures**: Leverage pytest fixtures for common setup

### Example Unit Test

```python
def test_get_access_token_success(self, mock_ibm_cloud_api, sample_api_key):
    """Test successful token retrieval."""
    # Act
    result = get_access_token(sample_api_key)
    
    # Assert
    assert result["access_token"] == "mock_access_token"
    assert result["token_type"] == "Bearer"
    
    # Verify API was called correctly
    mock_ibm_cloud_api['post'].assert_called_once()
```

## 🔗 Integration Testing Guidelines

### Test Categories

1. **Terraform Validation Tests**
   - Configuration validation
   - Format checking
   - Provider setup

2. **Terraform Planning Tests**
   - Plan generation
   - Resource validation
   - Variable validation

3. **Deployment Tests** (Slow)
   - Actual resource creation
   - Output validation
   - Cleanup verification

### Best Practices

1. **Use unique resource names**: Avoid conflicts with parallel tests
2. **Always clean up**: Destroy resources after tests
3. **Set timeouts**: Prevent tests from running indefinitely
4. **Test multiple regions**: Ensure cross-region compatibility
5. **Mock when possible**: Use real resources only when necessary

### Example Integration Test

```python
@pytest.mark.integration
@pytest.mark.slow
def test_minimal_deployment(self, terraform_helper, test_tfvars_file):
    """Test minimal deployment of Symphony cluster."""
    # Plan
    plan_result = terraform_helper.plan(test_tfvars_file)
    assert plan_result.returncode == 0
    
    # Apply
    apply_result = terraform_helper.apply()
    assert apply_result.returncode == 0
    assert "Apply complete!" in apply_result.stdout
```

## 🔒 Security Testing

### Tools Used

1. **Bandit** - Python security scanner
2. **Safety** - Python dependency vulnerability scanner
3. **Checkov** - Terraform security scanner
4. **Terrascan** - Infrastructure security scanner
5. **detect-secrets** - Secrets detection

### Running Security Tests

```bash
# Python security scan
bandit -r resources/ -f json -o bandit-report.json

# Dependency vulnerability scan
safety check

# Terraform security scan
checkov -d . --framework terraform

# Secrets detection
detect-secrets scan --baseline .secrets.baseline
```

## 🏗️ Terraform Testing

### TerraformTestHelper Class

The `TerraformTestHelper` class provides methods for Terraform operations:

```python
helper = TerraformTestHelper("/path/to/terraform")

# Initialize
helper.init()

# Validate
helper.validate()

# Plan
helper.plan("test.tfvars")

# Apply
helper.apply()

# Get outputs
outputs = helper.output()

# Destroy
helper.destroy("test.tfvars")
```

### Test Variables

Integration tests use a `test_variables` fixture that provides:

```python
{
    "api_key": "test_api_key",
    "cluster_prefix": "test-symphony-12345",
    "ssh_key_name": "test-ssh-key",
    "region": "us-south",
    "management_node_count": 1,
    "worker_node_min_count": 1,
    "spectrum_scale_enabled": False
}
```

## 🚀 Continuous Integration

### GitHub Actions Workflows

1. **CI Pipeline** (`.github/workflows/ci.yml`)
   - Code quality checks
   - Unit tests
   - Security scans
   - Integration tests (on main branch)

2. **Release Pipeline** (`.github/workflows/release.yml`)
   - Full test suite
   - Security validation
   - Package creation
   - Release notes generation

### Quality Gates

Tests must pass these quality gates:

- ✅ All unit tests pass
- ✅ Code coverage >= 80%
- ✅ No security vulnerabilities (high/critical)
- ✅ Code formatting checks pass
- ✅ Terraform validation passes
- ✅ Integration tests pass (for releases)

## 🐛 Debugging Tests

### Common Issues

1. **Import Errors**
   ```bash
   # Fix Python path issues
   export PYTHONPATH="${PYTHONPATH}:$(pwd)"
   ```

2. **IBM Cloud Authentication**
   ```bash
   # Verify API key
   ibmcloud iam api-key-get <key-name>
   ```

3. **Terraform State Issues**
   ```bash
   # Clean up state
   rm -rf .terraform/
   terraform init
   ```

### Debugging Commands

```bash
# Run tests with verbose output
pytest tests/ -v -s

# Run tests with debugging
pytest tests/ -v -s --pdb

# Run specific test with output
pytest tests/unit/test_remove_security_rule.py::TestGetAccessToken::test_get_access_token_success -v -s
```

## 📈 Test Metrics

### Coverage Metrics

- **Current coverage**: Check latest CI run
- **Target coverage**: 80% minimum
- **Coverage trend**: Should not decrease

### Performance Metrics

- **Unit test execution**: < 2 minutes
- **Integration test execution**: < 30 minutes
- **Security scan execution**: < 5 minutes

## 🔄 Test Maintenance

### Regular Tasks

1. **Update dependencies**: Keep test dependencies current
2. **Review test coverage**: Identify untested code paths
3. **Update fixtures**: Keep test data relevant
4. **Clean up resources**: Ensure integration tests clean up properly

### Adding New Tests

1. **For new Python modules**: Add corresponding unit tests
2. **For new Terraform modules**: Add validation and integration tests
3. **For new features**: Add both unit and integration tests
4. **For bug fixes**: Add regression tests

## 📚 Additional Resources

- [pytest documentation](https://docs.pytest.org/)
- [unittest.mock documentation](https://docs.python.org/3/library/unittest.mock.html)
- [Terraform testing best practices](https://www.terraform.io/docs/extend/testing/index.html)
- [IBM Cloud Terraform provider](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs)

## 🤝 Contributing to Tests

When contributing new tests:

1. Follow the existing test structure
2. Use appropriate markers (`@pytest.mark.unit`, `@pytest.mark.integration`)
3. Include docstrings for test methods
4. Mock external dependencies in unit tests
5. Clean up resources in integration tests
6. Update this documentation if needed

For more information, see [CONTRIBUTING.md](CONTRIBUTING.md).
