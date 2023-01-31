# Example Terraform EKS Mixed Node Cluster

This repository gives an example of how to set up a mixed Linux/Windows worker node EKS cluster that
actually works! It includes a good set of comments in the code which should hopefully help you
understand what is configured and why.

## Usage

Set the `AWS_PROFILE` environment variable to the AWS profile of choice, and then with Terraform
installed run `terraform init` followed by `terraform apply` to provision this cluster on your
account.
