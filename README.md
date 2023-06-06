# DiceCapstonePart2IaC
Terraform code to provision server and client VMs (IaC)

## Infrastructure provisioning
The `main.tf` file contains the code to create 2 VMs in the same public subnet and with the same ssh-key.

## Key creation
The key is created by running the command:
```bash
ssh-keygen
```

## Outputs
The script outputs the ami of the linux OS used in the server and client VMs.
The terraform also outputs the public ips of the server and the client VMs.

## Provisioning the Infrastructure
```bash
terraform init
terraform plan
terraform apply
```
