"""
Unit tests for remove_security_rule.py script.
"""

import json
import pytest
from unittest.mock import Mock, patch, MagicMock
import requests

# Import the module under test
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..', 'resources', 'common'))

from remove_security_rule import (
    get_access_token,
    delete_security_group_rule,
    main
)


class TestGetAccessToken:
    """Test cases for get_access_token function."""
    
    def test_get_access_token_success(self, mock_ibm_cloud_api, sample_api_key):
        """Test successful token retrieval."""
        result = get_access_token(sample_api_key)
        
        assert result["access_token"] == "mock_access_token"
        assert result["token_type"] == "Bearer"
        assert result["expires_in"] == 3600
        
        # Verify the API was called correctly
        mock_ibm_cloud_api['post'].assert_called_once()
        call_args = mock_ibm_cloud_api['post'].call_args
        assert "iam.cloud.ibm.com" in call_args[1]['url']
        assert call_args[1]['data']['apikey'] == sample_api_key
    
    def test_get_access_token_connection_error(self, sample_api_key):
        """Test connection error handling."""
        with patch('requests.post') as mock_post:
            mock_post.side_effect = requests.ConnectionError("Connection failed")
            
            with pytest.raises(requests.ConnectionError):
                get_access_token(sample_api_key)
    
    def test_get_access_token_http_error(self, sample_api_key):
        """Test HTTP error handling."""
        with patch('requests.post') as mock_post:
            mock_response = Mock()
            mock_response.raise_for_status.side_effect = requests.HTTPError("401 Unauthorized")
            mock_post.return_value = mock_response
            
            with pytest.raises(requests.HTTPError):
                get_access_token(sample_api_key)
    
    def test_get_access_token_invalid_json(self, sample_api_key):
        """Test invalid JSON response handling."""
        with patch('requests.post') as mock_post:
            mock_response = Mock()
            mock_response.raise_for_status.return_value = None
            mock_response.content = b"invalid json"
            mock_post.return_value = mock_response
            
            with pytest.raises(json.JSONDecodeError):
                get_access_token(sample_api_key)


class TestDeleteSecurityGroupRule:
    """Test cases for delete_security_group_rule function."""
    
    def test_delete_security_group_rule_success(self):
        """Test successful security group rule deletion."""
        with patch('requests.delete') as mock_delete:
            mock_response = Mock()
            mock_response.status_code = 204
            mock_response.raise_for_status.return_value = None
            mock_delete.return_value = mock_response
            
            result = delete_security_group_rule(
                region="us-south",
                access_token="test_token",
                security_group_id="sg-12345",
                security_group_rule_id="rule-12345"
            )
            
            assert result.status_code == 204
            mock_delete.assert_called_once()
            
            # Verify the correct URL was called
            call_args = mock_delete.call_args
            assert "us-south.iaas.cloud.ibm.com" in call_args[1]['url']
            assert "sg-12345" in call_args[1]['url']
            assert "rule-12345" in call_args[1]['url']
    
    def test_delete_security_group_rule_not_found(self):
        """Test handling of 404 error (rule not found)."""
        with patch('requests.delete') as mock_delete:
            mock_response = Mock()
            mock_response.status_code = 404
            mock_response.raise_for_status.side_effect = requests.HTTPError("404 Not Found")
            mock_delete.return_value = mock_response
            
            with pytest.raises(requests.HTTPError):
                delete_security_group_rule(
                    region="us-south",
                    access_token="test_token",
                    security_group_id="sg-12345",
                    security_group_rule_id="rule-12345"
                )
    
    def test_delete_security_group_rule_unauthorized(self):
        """Test handling of 401 error (unauthorized)."""
        with patch('requests.delete') as mock_delete:
            mock_response = Mock()
            mock_response.status_code = 401
            mock_response.raise_for_status.side_effect = requests.HTTPError("401 Unauthorized")
            mock_delete.return_value = mock_response
            
            with pytest.raises(requests.HTTPError):
                delete_security_group_rule(
                    region="us-south",
                    access_token="test_token",
                    security_group_id="sg-12345",
                    security_group_rule_id="rule-12345"
                )


class TestMain:
    """Test cases for main function."""
    
    @patch('remove_security_rule.delete_security_group_rule')
    @patch('remove_security_rule.get_access_token')
    def test_main_success(self, mock_get_token, mock_delete_rule):
        """Test successful main function execution."""
        # Setup mocks
        mock_get_token.return_value = {"access_token": "test_token"}
        mock_delete_rule.return_value = Mock(status_code=204)
        
        # Mock command line arguments
        test_args = [
            'remove_security_rule.py',
            '--api-key', 'test_api_key',
            '--region', 'us-south',
            '--security-group-id', 'sg-12345',
            '--security-group-rule-id', 'rule-12345'
        ]
        
        with patch('sys.argv', test_args):
            # Should not raise any exception
            main()
        
        # Verify functions were called
        mock_get_token.assert_called_once_with('test_api_key')
        mock_delete_rule.assert_called_once_with(
            'us-south', 'test_token', 'sg-12345', 'rule-12345'
        )
    
    @patch('remove_security_rule.get_access_token')
    def test_main_token_error(self, mock_get_token):
        """Test main function with token retrieval error."""
        mock_get_token.side_effect = requests.HTTPError("401 Unauthorized")
        
        test_args = [
            'remove_security_rule.py',
            '--api-key', 'test_api_key',
            '--region', 'us-south',
            '--security-group-id', 'sg-12345',
            '--security-group-rule-id', 'rule-12345'
        ]
        
        with patch('sys.argv', test_args):
            with pytest.raises(requests.HTTPError):
                main()
    
    def test_main_missing_arguments(self):
        """Test main function with missing required arguments."""
        test_args = ['remove_security_rule.py']
        
        with patch('sys.argv', test_args):
            with pytest.raises(SystemExit):
                main()


class TestIntegration:
    """Integration tests for the entire script."""
    
    @patch('requests.post')
    @patch('requests.delete')
    def test_full_workflow(self, mock_delete, mock_post):
        """Test the complete workflow from token to deletion."""
        # Setup token response
        mock_token_response = Mock()
        mock_token_response.status_code = 200
        mock_token_response.raise_for_status.return_value = None
        mock_token_response.content = json.dumps({
            "access_token": "test_access_token",
            "token_type": "Bearer",
            "expires_in": 3600
        }).encode()
        mock_post.return_value = mock_token_response
        
        # Setup delete response
        mock_delete_response = Mock()
        mock_delete_response.status_code = 204
        mock_delete_response.raise_for_status.return_value = None
        mock_delete.return_value = mock_delete_response
        
        # Execute the workflow
        token_data = get_access_token("test_api_key")
        result = delete_security_group_rule(
            "us-south",
            token_data["access_token"],
            "sg-12345",
            "rule-12345"
        )
        
        # Verify results
        assert token_data["access_token"] == "test_access_token"
        assert result.status_code == 204
        
        # Verify API calls
        mock_post.assert_called_once()
        mock_delete.assert_called_once()


# Parametrized tests for different regions
@pytest.mark.parametrize("region", [
    "us-south",
    "us-east",
    "eu-gb",
    "eu-de",
    "jp-tok",
    "au-syd"
])
def test_delete_security_group_rule_different_regions(region):
    """Test security group rule deletion across different regions."""
    with patch('requests.delete') as mock_delete:
        mock_response = Mock()
        mock_response.status_code = 204
        mock_response.raise_for_status.return_value = None
        mock_delete.return_value = mock_response
        
        delete_security_group_rule(
            region=region,
            access_token="test_token",
            security_group_id="sg-12345",
            security_group_rule_id="rule-12345"
        )
        
        # Verify the correct regional URL was used
        call_args = mock_delete.call_args
        assert f"{region}.iaas.cloud.ibm.com" in call_args[1]['url']
