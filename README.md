# Terraform azure self-hosted dev-ops agent

## Description

Terraform automation for provisioning azure Linux VM and installing Azure DevOps self-hosted agent.

## Instruction

Aftre git cloning the project, you should place your public ssh key named 'terraform-azure.pub' in ssh-keys/. You also need to be authenticated with azure. In this project azure I used azure cli athentication method. Specifically `azure login` after installing azure cli.

Run `terraform init && terraform apply` to provision resources

## License

This project is licensed under a custom restrictive license. All rights are reserved. You may not use, modify, or redistribute this code without explicit permission. Use by automated systems, including AI, is strictly prohibited.

For more details, refer to the [LICENSE](./LICENSE) file.
