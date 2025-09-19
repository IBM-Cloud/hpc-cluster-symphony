.PHONY: help install test lint format security clean all

# Default target
help:
	@echo "Available commands:"
	@echo "  install    - Install all dependencies"
	@echo "  test       - Run all tests"
	@echo "  lint       - Run all linting tools"
	@echo "  format     - Format all code"
	@echo "  security   - Run security scans"
	@echo "  clean      - Clean temporary files"
	@echo "  all        - Run install, format, lint, security, test"

# Install dependencies
install:
	@echo "Installing Python dependencies..."
	pip install -r requirements.txt
	@echo "Installing pre-commit hooks..."
	pre-commit install
	@echo "Installing Terraform..."
	@which terraform || (echo "Please install Terraform manually" && exit 1)
	@echo "Installing TFLint..."
	@which tflint || (echo "Please install TFLint manually" && exit 1)

# Run tests
test:
	@echo "Running Python tests..."
	pytest tests/ -v --cov=resources --cov-report=html --cov-report=term
	@echo "Running Terraform validation..."
	terraform init -backend=false
	terraform validate
	@echo "Running Terraform format check..."
	terraform fmt -check -recursive

# Run linting
lint:
	@echo "Running Python linting..."
	pylint resources/**/*.py
	flake8 resources/ tests/
	mypy resources/ --ignore-missing-imports
	@echo "Running Terraform linting..."
	tflint --recursive

# Format code
format:
	@echo "Formatting Python code..."
	black resources/ tests/
	isort resources/ tests/
	@echo "Formatting Terraform code..."
	terraform fmt -recursive

# Run security scans
security:
	@echo "Running Python security scan..."
	bandit -r resources/ -f json -o bandit-report.json || true
	safety check
	@echo "Running Terraform security scan..."
	checkov -d . --framework terraform --output json --output-file checkov-report.json || true
	terrascan scan -t terraform -d . -o json > terrascan-report.json || true

# Clean temporary files
clean:
	@echo "Cleaning temporary files..."
	find . -type f -name "*.pyc" -delete
	find . -type d -name "__pycache__" -delete
	rm -rf .pytest_cache/
	rm -rf htmlcov/
	rm -rf .coverage
	rm -rf *.json
	rm -rf .terraform/

# Run all checks
all: install format lint security test
	@echo "All checks completed successfully!"
