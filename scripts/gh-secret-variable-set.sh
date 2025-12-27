#! /bin/bash

# GitHub Login
gh auth login

# Set Environment
ENV="dev"

# Register Secrets
gh secret set -e "$ENV" -f .secrets

# Register Variables
gh variable set -e "$ENV" -f variables
