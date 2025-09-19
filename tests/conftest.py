"""
Pytest configuration and shared fixtures for IBM HPC Cluster Symphony tests.
"""

import json
import os
import tempfile
from typing import Dict, Any
from unittest.mock import Mock, patch

import pytest
import requests


@pytest.fixture
def mock_ibm_cloud_api():
    """Mock IBM Cloud API responses."""
    with patch('requests.post') as mock_post, \
         patch('requests.get') as mock_get, \
         patch('requests.delete') as mock_delete:
        
        # Mock token response
        mock_post.return_value.status_code = 200
        mock_post.return_value.json.return_value = {
            "access_token": "mock_access_token",
            "token_type": "Bearer",
            "expires_in": 3600
        }
        
        # Mock API responses
        mock_get.return_value.status_code = 200
        mock_get.return_value.json.return_value = {"result": "success"}
        
        mock_delete.return_value.status_code = 204
        
        yield {
            'post': mock_post,
            'get': mock_get,
            'delete': mock_delete
        }


@pytest.fixture
def sample_api_key():
    """Provide a sample API key for testing."""
    return "test_api_key_12345"


@pytest.fixture
def sample_security_group_data():
    """Provide sample security group data for testing."""
    return {
        "id": "sg-12345",
        "name": "test-security-group",
        "rules": [
            {
                "id": "rule-12345",
                "direction": "inbound",
                "protocol": "tcp",
                "port_min": 22,
                "port_max": 22
            }
        ]
    }


@pytest.fixture
def temp_terraform_dir():
    """Create a temporary directory with sample Terraform files."""
    with tempfile.TemporaryDirectory() as temp_dir:
        # Create sample main.tf
        main_tf_content = '''
resource "ibm_is_vpc" "test_vpc" {
  name = "test-vpc"
}

resource "ibm_is_security_group" "test_sg" {
  name = "test-sg"
  vpc  = ibm_is_vpc.test_vpc.id
}
'''
        with open(os.path.join(temp_dir, "main.tf"), "w") as f:
            f.write(main_tf_content)
        
        # Create sample variables.tf
        variables_tf_content = '''
variable "api_key" {
  type        = string
  sensitive   = true
  description = "IBM Cloud API key"
}

variable "region" {
  type        = string
  default     = "us-south"
  description = "IBM Cloud region"
}
'''
        with open(os.path.join(temp_dir, "variables.tf"), "w") as f:
            f.write(variables_tf_content)
        
        yield temp_dir


@pytest.fixture
def mock_terraform_output():
    """Mock Terraform output for testing."""
    return {
        "vpc_id": {
            "value": "vpc-12345",
            "type": "string"
        },
        "security_group_id": {
            "value": "sg-12345",
            "type": "string"
        }
    }


@pytest.fixture
def mock_environment_variables():
    """Mock environment variables for testing."""
    env_vars = {
        "IBM_CLOUD_API_KEY": "test_api_key",
        "TF_VAR_api_key": "test_api_key",
        "TF_VAR_region": "us-south"
    }
    
    with patch.dict(os.environ, env_vars):
        yield env_vars


@pytest.fixture
def mock_requests_session():
    """Mock requests session for HTTP calls."""
    session = Mock(spec=requests.Session)
    session.post.return_value.status_code = 200
    session.get.return_value.status_code = 200
    session.delete.return_value.status_code = 204
    return session


@pytest.fixture(scope="session")
def integration_config():
    """Configuration for integration tests."""
    return {
        "region": "us-south",
        "resource_group": "default",
        "timeout": 1800,  # 30 minutes
        "cleanup": True
    }


# Pytest markers
def pytest_configure(config):
    """Configure pytest markers."""
    config.addinivalue_line(
        "markers", "unit: mark test as a unit test"
    )
    config.addinivalue_line(
        "markers", "integration: mark test as an integration test"
    )
    config.addinivalue_line(
        "markers", "slow: mark test as slow running"
    )


def pytest_collection_modifyitems(config, items):
    """Modify test collection to add markers automatically."""
    for item in items:
        # Add unit marker to tests in unit directory
        if "unit" in str(item.fspath):
            item.add_marker(pytest.mark.unit)
        
        # Add integration marker to tests in integration directory
        if "integration" in str(item.fspath):
            item.add_marker(pytest.mark.integration)
            item.add_marker(pytest.mark.slow)
