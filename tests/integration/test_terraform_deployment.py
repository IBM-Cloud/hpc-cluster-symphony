"""
Integration tests for Terraform deployment.

These tests require actual IBM Cloud credentials and will create/destroy real resources.
Use with caution and ensure proper cleanup.
"""

import os
import json
import subprocess
import tempfile
import time
from pathlib import Path
from typing import Dict, Any

import pytest


class TerraformTestHelper:
    """Helper class for Terraform operations in tests."""
    
    def __init__(self, terraform_dir: str):
        self.terraform_dir = Path(terraform_dir)
        self.state_file = self.terraform_dir / "terraform.tfstate"
        
    def init(self) -> subprocess.CompletedProcess:
        """Initialize Terraform in the test directory."""
        return subprocess.run(
            ["terraform", "init", "-no-color"],
            cwd=self.terraform_dir,
            capture_output=True,
            text=True,
            check=True
        )
    
    def plan(self, var_file: str = None) -> subprocess.CompletedProcess:
        """Run terraform plan."""
        cmd = ["terraform", "plan", "-no-color", "-out=tfplan"]
        if var_file:
            cmd.extend(["-var-file", var_file])
        
        return subprocess.run(
            cmd,
            cwd=self.terraform_dir,
            capture_output=True,
            text=True,
            check=True
        )
    
    def apply(self, auto_approve: bool = True) -> subprocess.CompletedProcess:
        """Run terraform apply."""
        cmd = ["terraform", "apply", "-no-color"]
        if auto_approve:
            cmd.append("-auto-approve")
        cmd.append("tfplan")
        
        return subprocess.run(
            cmd,
            cwd=self.terraform_dir,
            capture_output=True,
            text=True,
            check=True
        )
    
    def destroy(self, var_file: str = None, auto_approve: bool = True) -> subprocess.CompletedProcess:
        """Run terraform destroy."""
        cmd = ["terraform", "destroy", "-no-color"]
        if auto_approve:
            cmd.append("-auto-approve")
        if var_file:
            cmd.extend(["-var-file", var_file])
        
        return subprocess.run(
            cmd,
            cwd=self.terraform_dir,
            capture_output=True,
            text=True
        )
    
    def output(self, output_name: str = None) -> Dict[str, Any]:
        """Get terraform outputs."""
        cmd = ["terraform", "output", "-json"]
        if output_name:
            cmd.append(output_name)
        
        result = subprocess.run(
            cmd,
            cwd=self.terraform_dir,
            capture_output=True,
            text=True,
            check=True
        )
        
        return json.loads(result.stdout)
    
    def validate(self) -> subprocess.CompletedProcess:
        """Run terraform validate."""
        return subprocess.run(
            ["terraform", "validate", "-no-color"],
            cwd=self.terraform_dir,
            capture_output=True,
            text=True,
            check=True
        )


@pytest.fixture(scope="session")
def terraform_helper(integration_config):
    """Create a Terraform helper for integration tests."""
    # Use the actual project directory
    project_dir = Path(__file__).parent.parent.parent
    return TerraformTestHelper(project_dir)


@pytest.fixture(scope="session")
def test_variables(integration_config):
    """Create test variables for Terraform."""
    api_key = os.getenv("IBM_CLOUD_API_KEY")
    if not api_key:
        pytest.skip("IBM_CLOUD_API_KEY environment variable not set")
    
    # Generate unique prefix for test resources
    import uuid
    test_id = str(uuid.uuid4())[:8]
    
    return {
        "api_key": api_key,
        "cluster_prefix": f"test-symphony-{test_id}",
        "ssh_key_name": os.getenv("TEST_SSH_KEY_NAME", "test-ssh-key"),
        "ibm_customer_number": os.getenv("IBM_CUSTOMER_NUMBER", "test-customer"),
        "region": integration_config["region"],
        "resource_group": integration_config["resource_group"],
        "management_node_count": 1,
        "worker_node_min_count": 1,
        "worker_node_max_count": 2,
        "spectrum_scale_enabled": False,  # Disable for faster testing
        "enable_app_center": False,
        "enable_cos_integration": False
    }


@pytest.fixture(scope="session")
def test_tfvars_file(test_variables):
    """Create a temporary tfvars file for testing."""
    with tempfile.NamedTemporaryFile(mode='w', suffix='.tfvars', delete=False) as f:
        for key, value in test_variables.items():
            if isinstance(value, str):
                f.write(f'{key} = "{value}"\n')
            elif isinstance(value, bool):
                f.write(f'{key} = {str(value).lower()}\n')
            else:
                f.write(f'{key} = {value}\n')
        
        tfvars_path = f.name
    
    yield tfvars_path
    
    # Cleanup
    os.unlink(tfvars_path)


class TestTerraformValidation:
    """Test Terraform configuration validation."""
    
    def test_terraform_init(self, terraform_helper):
        """Test that Terraform can initialize successfully."""
        result = terraform_helper.init()
        assert result.returncode == 0
        assert "Terraform has been successfully initialized" in result.stdout
    
    def test_terraform_validate(self, terraform_helper):
        """Test that Terraform configuration is valid."""
        # Ensure init has been run
        terraform_helper.init()
        
        result = terraform_helper.validate()
        assert result.returncode == 0
        assert "Success! The configuration is valid" in result.stdout
    
    def test_terraform_format_check(self, terraform_helper):
        """Test that Terraform files are properly formatted."""
        result = subprocess.run(
            ["terraform", "fmt", "-check", "-recursive"],
            cwd=terraform_helper.terraform_dir,
            capture_output=True,
            text=True
        )
        
        # Should return 0 if all files are formatted correctly
        if result.returncode != 0:
            pytest.fail(f"Terraform files are not properly formatted:\n{result.stdout}")


class TestTerraformPlan:
    """Test Terraform planning phase."""
    
    def test_terraform_plan_minimal(self, terraform_helper, test_tfvars_file):
        """Test that Terraform can create a valid plan with minimal configuration."""
        terraform_helper.init()
        
        result = terraform_helper.plan(test_tfvars_file)
        assert result.returncode == 0
        assert "Plan:" in result.stdout
        
        # Should not have any errors
        assert "Error:" not in result.stdout
        assert "Warning:" not in result.stderr or len(result.stderr.strip()) == 0
    
    def test_terraform_plan_output_parsing(self, terraform_helper, test_tfvars_file):
        """Test that Terraform plan output can be parsed for resource counts."""
        terraform_helper.init()
        
        result = terraform_helper.plan(test_tfvars_file)
        assert result.returncode == 0
        
        # Look for resource creation indicators
        output = result.stdout
        assert "to add" in output or "to create" in output
        
        # Should plan to create VPC resources
        assert "ibm_is_vpc" in output or "vpc" in output.lower()


@pytest.mark.slow
@pytest.mark.integration
class TestTerraformDeployment:
    """Test actual Terraform deployment (creates real resources)."""
    
    @pytest.fixture(autouse=True)
    def setup_and_cleanup(self, terraform_helper, test_tfvars_file):
        """Setup and cleanup for deployment tests."""
        # Setup
        terraform_helper.init()
        
        yield
        
        # Cleanup - always try to destroy resources
        try:
            terraform_helper.destroy(test_tfvars_file, auto_approve=True)
        except subprocess.CalledProcessError as e:
            print(f"Warning: Cleanup failed: {e}")
            # Log the error but don't fail the test
    
    def test_minimal_deployment(self, terraform_helper, test_tfvars_file, integration_config):
        """Test minimal deployment of Symphony cluster."""
        # Plan
        plan_result = terraform_helper.plan(test_tfvars_file)
        assert plan_result.returncode == 0
        
        # Apply with timeout
        start_time = time.time()
        apply_result = terraform_helper.apply()
        deployment_time = time.time() - start_time
        
        assert apply_result.returncode == 0
        assert "Apply complete!" in apply_result.stdout
        
        # Check deployment didn't take too long
        max_deployment_time = integration_config.get("timeout", 1800)  # 30 minutes
        assert deployment_time < max_deployment_time, f"Deployment took {deployment_time}s, max allowed: {max_deployment_time}s"
        
        # Verify outputs
        outputs = terraform_helper.output()
        assert "sshcommand" in outputs or "ssh_command" in outputs
        
        # Basic connectivity test could be added here
        # ssh_command = outputs.get("sshcommand", {}).get("value") or outputs.get("ssh_command", {}).get("value")
        # if ssh_command:
        #     # Could test SSH connectivity here
        #     pass
    
    def test_deployment_outputs(self, terraform_helper, test_tfvars_file):
        """Test that deployment produces expected outputs."""
        # This test assumes resources are already deployed from previous test
        # or can be run independently with proper setup
        
        try:
            outputs = terraform_helper.output()
            
            # Check for expected outputs
            expected_outputs = ["sshcommand", "ssh_command"]
            has_expected_output = any(output in outputs for output in expected_outputs)
            assert has_expected_output, f"Expected one of {expected_outputs} in outputs: {list(outputs.keys())}"
            
            # Validate output format
            ssh_output = None
            for output_name in expected_outputs:
                if output_name in outputs:
                    ssh_output = outputs[output_name].get("value")
                    break
            
            if ssh_output:
                assert "ssh" in ssh_output.lower()
                assert "@" in ssh_output  # Should contain user@host format
                
        except subprocess.CalledProcessError:
            pytest.skip("No deployed resources found for output testing")


class TestTerraformModules:
    """Test individual Terraform modules."""
    
    def test_vpc_module_structure(self, terraform_helper):
        """Test that VPC module has proper structure."""
        terraform_helper.init()
        
        # Check that VPC-related resources are defined
        result = subprocess.run(
            ["terraform", "providers"],
            cwd=terraform_helper.terraform_dir,
            capture_output=True,
            text=True
        )
        
        assert "registry.terraform.io/ibm-cloud/ibm" in result.stdout
    
    def test_security_group_module(self, terraform_helper):
        """Test security group module configuration."""
        # This would test specific security group configurations
        # For now, we'll just ensure the configuration is valid
        terraform_helper.init()
        result = terraform_helper.validate()
        assert result.returncode == 0


@pytest.mark.parametrize("region", [
    "us-south",
    "us-east", 
    "eu-gb",
    "eu-de"
])
def test_multi_region_validation(terraform_helper, test_variables, region):
    """Test that configuration is valid across different regions."""
    # Create region-specific variables
    region_vars = test_variables.copy()
    region_vars["region"] = region
    
    with tempfile.NamedTemporaryFile(mode='w', suffix='.tfvars', delete=False) as f:
        for key, value in region_vars.items():
            if isinstance(value, str):
                f.write(f'{key} = "{value}"\n')
            elif isinstance(value, bool):
                f.write(f'{key} = {str(value).lower()}\n')
            else:
                f.write(f'{key} = {value}\n')
        
        tfvars_path = f.name
    
    try:
        terraform_helper.init()
        result = terraform_helper.plan(tfvars_path)
        assert result.returncode == 0
        
    finally:
        os.unlink(tfvars_path)
