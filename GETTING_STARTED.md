# 🚀 Getting Started with IBM HPC Cluster Symphony Development

Welcome to the IBM HPC Cluster Symphony project! This guide will help you get up and running quickly with the development environment.

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

### Required Tools
- **Git** - Version control
- **Python** >= 3.8 - For scripts and testing
- **Terraform** >= 1.5.0 - Infrastructure as Code
- **IBM Cloud CLI** - For IBM Cloud integration
- **Make** (optional) - For automation commands

### IBM Cloud Setup
1. **Create IBM Cloud Account**: [Sign up here](https://cloud.ibm.com/registration)
2. **Generate API Key**: 
   ```bash
   ibmcloud iam api-key-create my-dev-key --file ~/.ibm-api-key.json
   ```
3. **Create SSH Key**: In IBM Cloud Console → VPC Infrastructure → SSH Keys

## 🛠️ Development Environment Setup

### 1. Clone and Setup Repository

```bash
# Clone the repository
git clone https://github.com/IBM/hpc-cluster-symphony.git
cd hpc-cluster-symphony

# Create your feature branch
git checkout -b feature/your-feature-name
```

### 2. Install Dependencies

```bash
# Using Make (recommended)
make install

# Or manually
pip install -r requirements.txt
pre-commit install
```

### 3. Configure Environment Variables

Create a `.env` file (never commit this!):
```bash
# IBM Cloud Configuration
export IBM_CLOUD_API_KEY="your-api-key-here"
export TF_VAR_api_key="your-api-key-here"
export IBM_CUSTOMER_NUMBER="your-customer-number"

# Test Configuration
export TEST_SSH_KEY_NAME="your-test-ssh-key"
export TF_VAR_ssh_key_name="your-test-ssh-key"
```

Load the environment:
```bash
source .env
```

## ✅ Verify Your Setup

### 1. Run Quality Checks
```bash
# Format code
make format

# Run linting
make lint

# Run security scans
make security
```

### 2. Run Unit Tests
```bash
# Run all unit tests
make test

# Or specifically unit tests
pytest tests/unit/ -v
```

### 3. Validate Terraform
```bash
# Initialize Terraform
terraform init -backend=false

# Validate configuration
terraform validate

# Check formatting
terraform fmt -check -recursive
```

## 🧪 Your First Contribution

### Option 1: Fix a Simple Issue
1. Look for issues labeled `good first issue`
2. Comment on the issue to claim it
3. Create a branch: `git checkout -b fix/issue-number`
4. Make your changes
5. Add tests for your changes
6. Submit a pull request

### Option 2: Add Tests (Great Starting Point!)
The project needs more test coverage. You can:

1. **Add unit tests** for existing Python scripts:
   ```bash
   # Create test file
   touch tests/unit/test_new_module.py
   
   # Follow the pattern in existing tests
   # See tests/unit/test_remove_security_rule.py as example
   ```

2. **Add integration tests** for Terraform modules:
   ```bash
   # Add to tests/integration/
   # Follow the pattern in test_terraform_deployment.py
   ```

### Option 3: Improve Documentation
1. Update README.md with missing information
2. Add code comments to complex functions
3. Create examples in the `sample/` directory

## 📝 Development Workflow

### 1. Before Making Changes
```bash
# Pull latest changes
git pull origin main

# Create feature branch
git checkout -b feature/your-feature

# Verify everything works
make all
```

### 2. Making Changes
```bash
# Make your changes
# Add tests for new functionality
# Update documentation

# Run checks frequently
make format  # Format code
make lint    # Check code quality
make test    # Run tests
```

### 3. Before Committing
```bash
# Run full check suite
make all

# Check what you're committing
git diff --staged

# Commit with descriptive message
git commit -m "feat: add comprehensive testing infrastructure

- Add unit tests for Python scripts
- Add integration tests for Terraform
- Add CI/CD pipeline with GitHub Actions
- Add security scanning with Checkov and Bandit"
```

### 4. Submitting Pull Request
```bash
# Push your branch
git push origin feature/your-feature

# Create pull request on GitHub
# Fill out the PR template completely
# Wait for review and address feedback
```

## 🎯 Common Development Tasks

### Adding a New Python Script Test
```bash
# 1. Create test file
touch tests/unit/test_your_script.py

# 2. Use this template:
cat > tests/unit/test_your_script.py << 'EOF'
"""
Unit tests for your_script.py
"""
import pytest
from unittest.mock import Mock, patch

# Import your module
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..', 'resources', 'common'))

from your_script import your_function

class TestYourFunction:
    def test_success_case(self):
        """Test successful execution."""
        result = your_function("test_input")
        assert result == "expected_output"
EOF

# 3. Run the test
pytest tests/unit/test_your_script.py -v
```

### Adding a New Terraform Module Test
```bash
# 1. Add to tests/integration/test_terraform_deployment.py
# 2. Follow the existing pattern
# 3. Use TerraformTestHelper class
# 4. Always include cleanup
```

### Running Specific Test Categories
```bash
# Only unit tests
pytest tests/unit/ -v

# Only integration tests
pytest tests/integration/ -v -m integration

# Skip slow tests
pytest tests/ -v -m "not slow"

# Run tests with coverage
pytest tests/unit/ -v --cov=resources --cov-report=html
```

## 🔍 Debugging Common Issues

### Import Errors
```bash
# Fix Python path
export PYTHONPATH="${PYTHONPATH}:$(pwd)"

# Or add to your script
import sys
sys.path.insert(0, '/path/to/project')
```

### Terraform Issues
```bash
# Clean state
rm -rf .terraform/
terraform init -backend=false

# Check provider versions
terraform version
```

### Test Failures
```bash
# Run with verbose output
pytest tests/ -v -s

# Run with debugging
pytest tests/ -v -s --pdb

# Check coverage
pytest tests/ --cov=resources --cov-report=term-missing
```

### Pre-commit Hook Failures
```bash
# Run hooks manually
pre-commit run --all-files

# Skip hooks temporarily (not recommended)
git commit --no-verify
```

## 📚 Learning Resources

### Project-Specific
- [CONTRIBUTING.md](CONTRIBUTING.md) - Detailed contribution guidelines
- [README_TESTING.md](README_TESTING.md) - Testing infrastructure details
- [Sample configurations](sample/) - Example configurations

### External Resources
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)
- [pytest Documentation](https://docs.pytest.org/)
- [IBM Cloud Terraform Provider](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs)
- [Python Testing Best Practices](https://realpython.com/python-testing/)

## 🤝 Getting Help

### Where to Ask Questions
1. **GitHub Issues** - For bugs and feature requests
2. **GitHub Discussions** - For questions and general discussion
3. **Pull Request Comments** - For code-specific questions

### What to Include When Asking for Help
1. **Environment details**: OS, Python version, Terraform version
2. **Steps to reproduce**: What you did
3. **Expected vs actual behavior**: What should happen vs what happened
4. **Error messages**: Full error output
5. **Configuration**: Relevant config files (sanitized)

## 🎉 Your First Successful Contribution

Once your first PR is merged:

1. **Celebrate!** 🎉 You've contributed to an enterprise-grade infrastructure project
2. **Update your local main branch**:
   ```bash
   git checkout main
   git pull origin main
   git branch -d feature/your-feature  # Clean up
   ```
3. **Look for more issues** to work on
4. **Help other contributors** by reviewing PRs
5. **Share your experience** in discussions

## 🚀 Next Steps

After your first contribution:

- **Explore advanced features**: Spectrum Scale, Windows nodes, multi-region
- **Improve CI/CD**: Add more sophisticated testing
- **Enhance security**: Add more security checks and policies
- **Optimize performance**: Profile and optimize Terraform execution
- **Add monitoring**: Implement observability features

Welcome to the team! 🚀
