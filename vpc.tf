# AWS VPC
# -----------------------------------------------------------------------------
# This configuration builds out the VPC that our EKS cluster will be
# provisioned against.

# This defines the VPC that our EKS cluster will be networked within.
# Module Docs: https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/3.19.0
module "cluster_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = "${local.cluster_name}-cluster"
  azs  = slice(data.aws_availability_zones.current_region.names, 0, 3)

  # Configure IP subnetting.
  cidr            = "10.0.0.0/16"
  private_subnets = ["10.0.0.0/19", "10.0.32.0/19", "10.0.64.0/19"]
  public_subnets  = ["10.0.96.0/19", "10.0.128.0/19", "10.0.160.0/19"]
  intra_subnets   = ["10.0.192.0/20", "10.0.208.0/20", "10.0.224.0/20"]

  # Enable routing to the outside internet via a NAT gateway.
  enable_nat_gateway = true
  single_nat_gateway = true

  # Allow DNS names to be mapped to resources attached to this VPC.
  enable_dns_hostnames = true

  # Logs all traffic across ENI interfaces attached to this VPC.
  enable_flow_log                      = true
  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true

  # These tags prepare us to support the Amazon Load Balancer Controller.
  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  }

  # These tags prepare us to support the Amazon Load Balancer Controller.
  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
  }
}

# The current region is implied by provider.aws.region's value in terraform.tf
data "aws_availability_zones" "current_region" {}
