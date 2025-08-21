#!/usr/bin/env python3
"""
Integration tests for wolskinet.infrastructure collection
Uses pytest and testinfra for testing Ansible collection functionality
"""

import pytest
import testinfra
import os
import yaml
from pathlib import Path


# Test collection structure and metadata
class TestCollectionStructure:
    def test_galaxy_yml_exists(self):
        """Test that galaxy.yml exists and is valid"""
        galaxy_file = Path('galaxy.yml')
        assert galaxy_file.exists(), "galaxy.yml file must exist"
        
        with open(galaxy_file, 'r') as f:
            galaxy_config = yaml.safe_load(f)
        
        assert galaxy_config['namespace'] == 'wolskinet'
        assert galaxy_config['name'] == 'infrastructure'
        assert 'version' in galaxy_config
        assert 'license' in galaxy_config
        assert galaxy_config['license'] == ['GPL-3.0-or-later']

    def test_required_directories_exist(self):
        """Test that required collection directories exist"""
        required_dirs = [
            'roles',
            'utilities',
            'molecule',
            'docs'
        ]
        
        for directory in required_dirs:
            assert Path(directory).exists(), f"Directory {directory} must exist"

    def test_roles_exist(self):
        """Test that expected roles exist"""
        expected_roles = [
            'basic_setup',
            'container_platform', 
            'maintenance'
        ]
        
        roles_dir = Path('roles')
        for role in expected_roles:
            role_path = roles_dir / role
            assert role_path.exists(), f"Role {role} must exist"
            assert (role_path / 'tasks' / 'main.yml').exists(), f"Role {role} must have tasks/main.yml"

    def test_molecule_scenarios_exist(self):
        """Test that Molecule test scenarios exist"""
        expected_scenarios = [
            'default',
            'basic_setup',
            'container_platform',
            'discovery'
        ]
        
        molecule_dir = Path('molecule')
        for scenario in expected_scenarios:
            scenario_path = molecule_dir / scenario
            assert scenario_path.exists(), f"Molecule scenario {scenario} must exist"
            assert (scenario_path / 'molecule.yml').exists(), f"Scenario {scenario} must have molecule.yml"


# Test role configurations
class TestRoleConfigurations:
    def test_basic_setup_role_structure(self):
        """Test basic_setup role has proper structure"""
        role_path = Path('roles/basic_setup')
        required_files = [
            'tasks/main.yml',
            'vars/main.yml',
            'defaults/main.yml',
            'meta/main.yml'
        ]
        
        for file_path in required_files:
            full_path = role_path / file_path
            assert full_path.exists(), f"File {file_path} must exist in basic_setup role"

    def test_container_platform_role_structure(self):
        """Test container_platform role has proper structure"""
        role_path = Path('roles/container_platform')
        required_files = [
            'tasks/main.yml',
            'tasks/install-Debian.yml',
            'tasks/install-Archlinux.yml',
            'vars/main.yml',
            'defaults/main.yml',
            'meta/main.yml',
            'templates/docker-compose.yml.j2'
        ]
        
        for file_path in required_files:
            full_path = role_path / file_path
            assert full_path.exists(), f"File {file_path} must exist in container_platform role"

    def test_role_metadata_valid(self):
        """Test that role metadata is valid"""
        roles_dir = Path('roles')
        for role_dir in roles_dir.iterdir():
            if role_dir.is_dir():
                meta_file = role_dir / 'meta' / 'main.yml'
                if meta_file.exists():
                    with open(meta_file, 'r') as f:
                        meta_config = yaml.safe_load(f)
                    
                    assert 'galaxy_info' in meta_config, f"Role {role_dir.name} must have galaxy_info in meta"
                    assert 'author' in meta_config['galaxy_info'], f"Role {role_dir.name} must have author"
                    assert 'license' in meta_config['galaxy_info'], f"Role {role_dir.name} must have license"


# Test utilities structure
class TestUtilities:
    def test_discovery_utility_exists(self):
        """Test that infrastructure discovery utility exists"""
        discovery_playbook = Path('utilities/playbooks/discover-infrastructure.yml')
        assert discovery_playbook.exists(), "Discovery playbook must exist"
        
        with open(discovery_playbook, 'r') as f:
            playbook_content = yaml.safe_load(f)
        
        assert isinstance(playbook_content, list), "Playbook must be a list of plays"
        assert len(playbook_content) > 0, "Playbook must have at least one play"

    def test_discovery_templates_exist(self):
        """Test that discovery templates exist"""
        templates_dir = Path('roles/discovery/templates')
        expected_templates = [
            'inventory.yml.j2',
            'host_vars.yml.j2',
            'group_vars.yml.j2',
            'package-replication.yml.j2',
            'secrets-template.yml.j2'
        ]
        
        for template in expected_templates:
            template_path = templates_dir / template
            assert template_path.exists(), f"Template {template} must exist"


# Test documentation
class TestDocumentation:
    def test_readme_exists(self):
        """Test that README file exists"""
        readme_file = Path('README.md')
        assert readme_file.exists(), "README.md file must exist"
        
        with open(readme_file, 'r') as f:
            content = f.read()
        
        assert 'wolskinet.infrastructure' in content, "README must mention collection name"
        assert 'Installation' in content, "README must have installation instructions"

    def test_changelog_exists(self):
        """Test that changelog exists"""
        changelog_file = Path('CHANGELOG.md')
        if changelog_file.exists():
            with open(changelog_file, 'r') as f:
                content = f.read()
            assert len(content) > 0, "Changelog must not be empty"

    def test_docs_directory_structure(self):
        """Test that docs directory has proper structure"""
        docs_dir = Path('docs')
        if docs_dir.exists():
            expected_docs = [
                'roles',
                'utilities'
            ]
            
            for doc_type in expected_docs:
                doc_path = docs_dir / doc_type
                if doc_path.exists():
                    assert doc_path.is_dir(), f"Documentation {doc_type} must be a directory"


# Test CI/CD configurations
class TestCICD:
    def test_gitlab_ci_exists(self):
        """Test that GitLab CI configuration exists"""
        gitlab_ci = Path('.gitlab-ci.yml')
        assert gitlab_ci.exists(), "GitLab CI configuration must exist"
        
        with open(gitlab_ci, 'r') as f:
            ci_config = yaml.safe_load(f)
        
        assert 'stages' in ci_config, "GitLab CI must define stages"
        expected_stages = ['validate', 'test-roles', 'test-integration', 'build']
        for stage in expected_stages:
            assert stage in ci_config['stages'], f"Stage {stage} must be defined"

    def test_github_workflows_exist(self):
        """Test that GitHub workflows exist"""
        workflows_dir = Path('.github/workflows')
        assert workflows_dir.exists(), "GitHub workflows directory must exist"
        
        expected_workflows = [
            'ci.yml',
            'sync-from-gitlab.yml',
            'release.yml'
        ]
        
        for workflow in expected_workflows:
            workflow_path = workflows_dir / workflow
            assert workflow_path.exists(), f"GitHub workflow {workflow} must exist"

    def test_molecule_config_valid(self):
        """Test that Molecule configurations are valid"""
        molecule_dir = Path('molecule')
        for scenario_dir in molecule_dir.iterdir():
            if scenario_dir.is_dir():
                molecule_yml = scenario_dir / 'molecule.yml'
                if molecule_yml.exists():
                    with open(molecule_yml, 'r') as f:
                        molecule_config = yaml.safe_load(f)
                    
                    assert 'driver' in molecule_config, f"Molecule scenario {scenario_dir.name} must have driver"
                    assert 'platforms' in molecule_config, f"Molecule scenario {scenario_dir.name} must have platforms"
                    assert 'provisioner' in molecule_config, f"Molecule scenario {scenario_dir.name} must have provisioner"


# Test security configurations
class TestSecurity:
    def test_no_hardcoded_secrets(self):
        """Test that no hardcoded secrets exist in the collection"""
        sensitive_patterns = [
            'password:',
            'secret:',
            'api_key:',
            'private_key:',
            'ssh://git@'
        ]
        
        # Check YAML files for potential secrets
        yaml_files = list(Path('.').rglob('*.yml')) + list(Path('.').rglob('*.yaml'))
        
        for yaml_file in yaml_files:
            if 'test' in str(yaml_file).lower():
                continue  # Skip test files
                
            with open(yaml_file, 'r') as f:
                content = f.read().lower()
                
            for pattern in sensitive_patterns:
                if pattern in content:
                    # Allow template variables and documentation
                    if '{{' in content or 'example' in str(yaml_file).lower():
                        continue
                    pytest.fail(f"Potential hardcoded secret found in {yaml_file}: {pattern}")

    def test_vault_templates_secure(self):
        """Test that vault templates contain only placeholder values"""
        vault_template = Path('roles/discovery/templates/secrets-template.yml.j2')
        if vault_template.exists():
            with open(vault_template, 'r') as f:
                content = f.read()
            
            # Should contain placeholder patterns, not actual secrets
            assert 'CHANGEME' in content or '{{ ' in content, "Vault template must use placeholders"
            assert 'your_' in content.lower() or 'changeme' in content.lower(), "Vault template must use example values"


if __name__ == '__main__':
    pytest.main([__file__, '-v'])