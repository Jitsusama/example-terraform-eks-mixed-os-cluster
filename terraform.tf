# Global Terraform configuration.
terraform {
  # These are provider versions required by the VPC & EKS modules we're using.
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.47"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 3.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.10"
    }
  }

  required_version = "~> 1.0"
}

provider "aws" {
  region = "us-east-2"
}

provider "kubernetes" {
  host                   = module.cluster_eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.cluster_eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.cluster_eks.cluster_name]
  }
}
