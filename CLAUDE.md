# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Azure Terraform Modules - Reusable Terraform module library for managing infrastructure on Azure with 45+ modules focused on security, availability, and scalability.

**Tech Stack:**

- IaC: Terraform (HCL)
- Cloud Provider: Microsoft Azure
- Linting: TFLint (azurerm plugin v0.29.0)
- Security Scanning: Trivy
- Testing: terraform test, terraform-compliance

## Working Guidelines

**Language Policy:**
- **Think in English:** Perform all reasoning and analysis in English
- **Output in Japanese:** All responses, comments, and documentation should be in Japanese
- **Commit Messages in Japanese:** Write all git commit messages in Japanese using Conventional Commits format

## Development Commands

### Terraform Workflow

```bash
# Initialize and format
cd envs/dev
terraform init
terraform fmt -recursive

# Validation
terraform validate

# Linting (requires tflint)
tflint --init  # First time or plugin updates
tflint

# Plan and apply
terraform plan
terraform apply

# Security scan (CRITICAL and HIGH only)
trivy config envs/dev/ --severity HIGH,CRITICAL
```

### Testing

```bash
# Run Terraform native tests (dev environment)
cd envs/dev
terraform test                                    # All tests
terraform test -filter=tests/storage.tftest.hcl  # Specific test file

# Run compliance tests (terraform-compliance)
cd tests/compliance
make plan dev      # Generate plan for dev environment
make test dev      # Run all compliance tests
make test-security dev   # Security tests only
make test-critical dev   # Critical tests only

# Or use uvx directly (no installation needed)
uvx terraform-compliance -f features -p ../../envs/dev/tfplan.json
```

### Validation Pipeline (Pre-Commit)

Git hooks automatically run validation before commit:

```bash
# Enable pre-commit hooks
git config core.hooksPath .githooks

# Manual validation (same as pre-commit)
bash .claude/scripts/terraform-pre-commit-validation.sh
```

The pre-commit hook runs:

1. `terraform validate` for each environment
2. `tflint` for each environment
3. `trivy config` scan (CRITICAL, HIGH only)

Skip validation only in emergencies: `git commit --no-verify`

## Module Structure

### Standard 3-File Pattern

Every module follows this structure:

```
modules/<module_name>/
├── variables.tf          # Input variables (alphabetically ordered)
├── <module_name>.tf      # Resource definitions
└── outputs.tf            # Output values (alphabetically ordered)
```

### Common Variables Pattern

All modules use `var.common` for consistency:

```hcl
variable "common" {
  type = object({
    project  = string
    env      = string
    location = string
  })
}
```

### Resource Naming Convention

Pattern: `<resource_type>-<name>-<project>-<env>`

```hcl
name = "webapp-${each.value.name}-${var.common.project}-${var.common.env}"
```

**Exception:** Storage Accounts have constraints:

```hcl
name = "st${each.value.name}${var.common.project}${var.common.env}${random_string.suffix.result}"
```

## Architecture Patterns

### Security Requirements (Mandatory)

All web-facing resources MUST implement:

```hcl
https_only                                    = true
minimum_tls_version                           = "1.2"
ftp_publish_basic_authentication_enabled      = false
webdeploy_publish_basic_authentication_enabled = false
ip_restriction_default_action                 = "Deny"
ftps_state                                    = "Disabled"
```

### Identity Management

- **Prefer:** User Assigned Managed Identity
- **Avoid:** System Assigned Identity (complex to manage)

```hcl
identity {
  type         = "UserAssigned"
  identity_ids = [var.user_assigned_identity_id]
}

key_vault_reference_identity_id = var.user_assigned_identity_id
```

### VNet Integration

```hcl
vnet_route_all_enabled     = true
virtual_network_subnet_id  = var.subnet_id
```

### Dynamic Blocks Pattern

Use `for_each` for multiple resources:

```hcl
resource "azurerm_linux_web_app" "this" {
  for_each = var.app_service
  name     = "webapp-${each.value.name}-${var.common.project}-${var.common.env}"
  # ...
}
```

Use `dynamic` for conditional blocks:

```hcl
dynamic "cors" {
  for_each = each.value.site_config.cors != null ? [true] : []
  content {
    allowed_origins = var.allowed_origins[each.key]
  }
}
```

### CI/CD Lifecycle Management

Ignore CI/CD-managed values:

```hcl
lifecycle {
  ignore_changes = [
    site_config[0].application_stack[0].docker_image_name,
    tags["hidden-link: /app-insights-conn-string"],
  ]
}
```

## Code Style Conventions

### Naming

- Use snake_case: `resource_group_name` ✅, `resourceGroupName` ❌
- No type redundancy: `azurerm_virtual_network.main` ✅, `azurerm_virtual_network.vnet_main` ❌

### Comments

- Write in Japanese for Azure-specific configurations
- Use `####` for section separators
- Comment sparingly - code should be self-explanatory

### Variables

Every variable MUST have:

```hcl
variable "example" {
  description = "Clear explanation in Japanese"
  type        = string
  default     = "value"  # Optional

  validation {  # Optional, for constrained values
    condition     = contains(["dev", "stg", "prod"], var.example)
    error_message = "Must be dev, stg, or prod."
  }
}
```

## Task Completion Checklist

After ANY code changes:

```bash
# 1. Format
terraform fmt -recursive

# 2. Validate
terraform validate

# 3. Lint
tflint

# 4. Security scan
trivy config envs/dev/ --severity HIGH,CRITICAL

# 5. Plan
cd envs/dev && terraform plan

# 6. Test
terraform test  # If applicable
```

Before creating a PR:

- [ ] All validation passes (format, validate, lint, security scan)
- [ ] Tests pass (if modified test files)
- [ ] Commit messages follow convention
- [ ] No `.terraform/`, `*.tfstate`, or binary files included

## Git Commit Convention

### Commit Message Format

**REQUIREMENT: Write ALL commit messages in Japanese** using Conventional Commits format:

```
<type>: <description>

<detailed explanation if needed>
```

Types: `feat`, `fix`, `refactor`, `docs`, `chore`

**IMPORTANT:** Do NOT include Claude Code signature:

```
# ❌ DON'T include:
🤖 Generated with [Claude Code](https://claude.com/claude-code)
Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

## Security Best Practices

### Storage Account

```hcl
min_tls_version                = "TLS1_2"
enable_https_traffic_only      = true
public_network_access_enabled  = false  # Control as needed
shared_key_access_enabled      = false
```

### Key Vault

```hcl
purge_protection_enabled    = true
soft_delete_retention_days  = 90
enable_rbac_authorization   = true
```

### Database (SQL/Cosmos)

```hcl
minimum_tls_version = "1.2"
# Enable Azure AD authentication
# Enable automated backups
```

## Testing Strategy

### terraform test (Native Tests)

- Location: `envs/dev/tests/*.tftest.hcl`
- Scope: Environment-specific validation
- Cost: Free (plan tests don't create resources)
- Run: `terraform test` in `envs/dev/`

### terraform-compliance (BDD Tests)

- Location: `tests/compliance/features/`
- Scope: Cross-environment policy validation
- Categories: security, network, tagging, data-protection
- Run: `make test dev` in `tests/compliance/`

## MCP Servers and Tools

This project is configured to use:

### Azure MCP (Terraform development)

```bash
# Research Azure service documentation
mcp__Azure__documentation('<service_name>')
mcp__Azure__azureterraformbestpractices('<service_name>')
mcp__Azure__get_bestpractices('<service_name>')
```

### Terraform MCP (Provider research)

```bash
# Research Terraform providers
mcp__Terraform__get_provider_details('hashicorp', 'azurerm')
mcp__Terraform__get_provider_details('azure', 'azapi')
mcp__Terraform__get_latest_provider_version()
```

## Project-Specific Skills

### `/terraform-code` Skill

Triggers on: "write terraform", "create tf module", "implement infrastructure as code"

Workflow:

1. **Research Phase:** Launch parallel agents for Azure MCP + Terraform MCP research
2. **Implementation:** Follow HashiCorp style guide
3. **Validation:** Run validation scripts before completion

See `.claude/skills/terraform-code/SKILL.md` for detailed workflow.

## Directory Organization

```
azure-terraform-modules/
├── modules/              # 45+ reusable modules
│   ├── app_service/
│   ├── function/
│   ├── vnet/
│   ├── key_vault/
│   └── ...
├── envs/                 # Environment configurations
│   └── dev/
│       ├── main.tf
│       ├── variables.tf
│       ├── terraform.tfvars
│       └── tests/        # terraform test files
├── tests/
│   └── compliance/       # terraform-compliance BDD tests
├── scripts/              # Utility scripts
├── .githooks/            # Pre-commit validation hooks
└── .claude/              # Claude Code configuration
    ├── skills/           # Project-specific skills
    └── scripts/          # Validation scripts
```

## Key Files

- `.githooks/pre-commit` - Automatic validation before commits
- `.tflint.hcl` - TFLint configuration (per environment)
- `envs/dev/check.tf` - Terraform check blocks for validation
- `tests/compliance/Makefile` - Compliance test automation

## Common Workflows

### Adding a New Module

```bash
# 1. Create module directory
mkdir -p modules/new_module

# 2. Create standard files
touch modules/new_module/{variables.tf,new_module.tf,outputs.tf}

# 3. Implement with security defaults
# (Use existing modules as reference)

# 4. Add to dev environment main.tf
# module "new_module" { ... }

# 5. Validate
terraform fmt -recursive
terraform validate
tflint
trivy config modules/new_module/

# 6. Test
cd envs/dev && terraform plan
```

### Debugging Issues

```bash
# Check state
terraform state list
terraform state show module.app_service.azurerm_linux_web_app.this["api"]

# Enable debug logging
export TF_LOG=DEBUG
terraform plan
unset TF_LOG

# Refresh state
terraform refresh
```

## Notes

- This repository uses Japanese comments for Azure-specific configurations
- All modules are designed for production use with security best practices
- Pre-commit hooks ensure code quality - avoid `--no-verify` unless emergency
- Tests should pass before merging PRs
- Use terraform-compliance for cross-environment policy enforcement
