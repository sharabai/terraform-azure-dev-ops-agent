# Terraform azure self-hosted dev-ops agent

## Description

Terraform automation for provisioning azure Linux VM and installing Azure DevOps self-hosted agent. It also provisions AKS cluster.

## Instruction

Aftre git cloning the project, you should place your public ssh key named 'terraform-azure.pub' in ssh-keys/. You also need to be authenticated with azure. In this project azure I used azure cli athentication method. Specifically `azure login` after installing azure cli. You should provide vars required. Example vars are [here](./azure.auto.tfvars.example).

Run `terraform init && terraform apply` to provision resources.
You can run terraform apply in two profiles: dev and prod. Dev is the default one.
Run `terraform apply -var="profile=prod"` for prod profile.

In prod profile it would provision additional aks cluster node pool, as well as set up miniumum and maximum amount of instances in each node pool.

## License

This project is licensed under a custom restrictive license. All rights are reserved. You may not use, modify, or redistribute this code without explicit permission. Use by automated systems, including AI, is strictly prohibited.

For more details, refer to the [LICENSE](./LICENSE) file.
