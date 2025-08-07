# Contributing to N8N ECS Terraform Module

Thank you for your interest in contributing to this enterprise-grade n8n deployment solution! This project demonstrates production-ready infrastructure as code practices and welcomes contributions that maintain these high standards.

## Project Goals

This Terraform module showcases:
- Enterprise-grade architecture for workflow automation platforms
- Production-ready patterns for AWS ECS Fargate deployments
- Security-first design with industry best practices
- Operational excellence through comprehensive monitoring and automation
- Infrastructure as Code mastery using Terraform

## How to Contribute

### Types of Contributions

We welcome various types of contributions:

- Bug Reports: Issues with infrastructure deployment or configuration
- Feature Requests: Enhancements to architecture or functionality  
- Documentation: Improvements to guides, examples, or explanations
- Code Improvements: Terraform optimizations or AWS best practices
- Security Enhancements: Security improvements or vulnerability fixes
- Monitoring: Additional CloudWatch metrics, alarms, or dashboards

### Before You Start

1. Review the Architecture: Understand the queue-mode n8n deployment pattern
2. Check Existing Issues: Avoid duplicate work by reviewing open issues
3. Understand the Scope: This module focuses on production-ready deployments
4. Follow AWS Best Practices: Ensure contributions align with AWS Well-Architected Framework

## Development Workflow

### Prerequisites

- Terraform >= 1.3.0
- AWS CLI configured with appropriate permissions
- Git for version control
- Understanding of AWS ECS, RDS, and networking concepts

### Setting Up Development Environment

```bash
# Clone the repository
git clone https://github.com/yourusername/terraform-n8n-ecs-module.git
cd terraform-n8n-ecs-module

# Initialize Terraform
terraform init

# Validate configuration
terraform validate
terraform fmt -check -recursive

# Create your feature branch
git checkout -b feature/your-feature-name
```

### Making Changes

1. Create a Feature Branch
   ```bash
   git checkout -b feature/descriptive-name
   ```

2. Follow Terraform Best Practices
   - Use meaningful variable names and descriptions
   - Add comprehensive comments for complex logic
   - Follow HCL formatting standards (`terraform fmt`)
   - Validate configurations (`terraform validate`)

3. Update Documentation
   - Update README.md for new features
   - Add examples for new configuration options
   - Update variable descriptions in variables.tf
   - Document any breaking changes

4. Test Your Changes
   ```bash
   # Format code
   terraform fmt -recursive
   
   # Validate syntax
   terraform validate
   
   # Plan deployment (don't apply in development)
   terraform plan -var-file="examples/development.tfvars"
   ```

### Commit Guidelines

Follow conventional commit format:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

Types:
- `feat`: New features or enhancements
- `fix`: Bug fixes
- `docs`: Documentation changes
- `refactor`: Code refactoring without functionality changes
- `perf`: Performance improvements
- `test`: Test additions or modifications
- `chore`: Maintenance tasks

Examples:
```
feat(ecs): add auto-scaling policies for webhook service
fix(rds): resolve subnet group validation issue
docs(readme): add troubleshooting section for common issues
refactor(variables): improve variable organization and validation
```

### Pull Request Process

1. Update Documentation: Ensure all changes are documented
2. Add Examples: Include usage examples for new features
3. Test Thoroughly: Validate configurations don't break existing deployments
4. Create Pull Request: Use the provided template
5. Code Review: Address feedback and iterate as needed

## Pull Request Template

When creating a pull request, please include:

```markdown
## Description
Brief description of changes and motivation

## Type of Change
- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Testing Performed
- [ ] Terraform fmt and validate passed
- [ ] Configuration tested with terraform plan
- [ ] Documentation updated and reviewed
- [ ] Examples updated (if applicable)

## Checklist
- [ ] My code follows the project's style guidelines
- [ ] I have performed a self-review of my code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings or errors
```

## Code Style Guidelines

### Terraform Standards

- Formatting: Use `terraform fmt` for consistent formatting
- Naming: Use descriptive names with underscores (snake_case)
- Comments: Add header comments for each major section
- Variables: Include comprehensive descriptions and validation rules
- Outputs: Document all outputs with operational context

### File Organization

```
terraform-n8n-ecs-module/
├── main.tf                    # Root module configuration
├── variables.tf               # Input variable definitions  
├── outputs.tf                 # Output value definitions
├── provider.tf                # Provider configurations
├── modules/                   # Reusable modules
│   ├── ecs/                  # ECS services and tasks
│   ├── rds/                  # Database resources
│   └── networking/           # VPC and networking
└── persistency/              # Persistent resources
```

### Documentation Standards

- Clear Explanations: Explain the "why" not just the "what"
- Architecture Context: Relate features to overall system design
- Operational Focus: Include operational procedures and troubleshooting
- Examples: Provide realistic usage examples
- Security Notes: Highlight security considerations and best practices

## Security Guidelines

### Infrastructure Security

- Least Privilege: IAM roles should have minimal required permissions
- Encryption: Enable encryption at rest and in transit
- Network Isolation: Use private subnets for application resources
- Secret Management: Use AWS Secrets Manager for sensitive data

### Code Security

- No Hardcoded Secrets: Never commit passwords, keys, or tokens
- Secure Defaults: Configure secure defaults for all resources
- Validation: Add input validation for security-sensitive variables
- Documentation: Document security implications of configuration choices

### Reporting Security Issues

## Architecture Principles

This module follows enterprise architecture principles:

### High Availability
- Multi-AZ deployment for all critical components
- Auto-scaling based on demand metrics
- Health checks and automatic recovery

### Security by Design
- Private subnet deployment for application resources
- SSL/TLS termination at load balancer level
- IAM roles with least privilege access
- Encryption for data at rest and in transit

### Operational Excellence
- Comprehensive monitoring and alerting
- Centralized logging with appropriate retention
- Infrastructure as Code with version control
- Automated deployment and rollback capabilities

### Cost Optimization
- Right-sizing recommendations for different environments
- Auto-scaling to match demand
- Reserved instance planning guidance
- Resource tagging for cost allocation

## Release Process

### Versioning Strategy

We follow [Semantic Versioning](https://semver.org/):
- MAJOR: Breaking changes that require user intervention
- MINOR: New features that are backward compatible
- PATCH: Bug fixes and minor improvements

### Release Checklist

- [ ] All tests passing
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Version tagged in Git
- [ ] Release notes published

## Getting Help

### Documentation
- README.md: Primary documentation and getting started guide
- modules/: Individual module documentation
- SECURITY.md: Security considerations and reporting

### Community
- Issues: Open GitHub issues for bugs and feature requests
- Discussions: Use GitHub Discussions for questions and ideas

### Professional Services

This module represents production-ready infrastructure patterns developed through enterprise experience. For professional consulting on:

- Custom Terraform Modules
- AWS Architecture Design
- DevOps Process Implementation
- Site Reliability Engineering

---

## Recognition

Contributors will be recognized in:
- Project README.md
- Release notes for significant contributions
- LinkedIn recommendations for professional contributors

Thank you for helping improve this enterprise infrastructure solution!

---

License: MIT  
