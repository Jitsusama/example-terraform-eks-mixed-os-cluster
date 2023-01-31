# AWS EKS Cluster
# -----------------------------------------------------------------------------
# This configuration builds out the EKS cluster that will be comprised of our
# mixed Linux and Windows worker nodes.

locals {
  cluster_name    = "eks-cluster"
  cluster_version = "1.24"
}

# This defines the EKS cluster that all workloads will run in.
# Module Docs: https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/19.5.1
module "cluster_eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = local.cluster_name
  cluster_version = local.cluster_version

  # Allow cluster creation/deletion/modification to take a while.
  cluster_timeouts = {
    create = "120m"
    update = "120m"
    delete = "120m"
  }

  # Configure cluster networking.
  vpc_id                   = module.cluster_vpc.vpc_id
  subnet_ids               = module.cluster_vpc.private_subnets
  control_plane_subnet_ids = module.cluster_vpc.intra_subnets

  # NOTE: Do *NOT* set this. Having a custom service CIDR breaks Windows networking.
  # cluster_service_ipv4_cidr = "10.1.0.0/16"

  # Enable logging for all internal Kubernetes resources.
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # Allow outside world access to the Kubernetes API.
  cluster_endpoint_public_access = true

  # Allow the cluster to create network interfaces and assign IP addresses.
  # See: https://docs.aws.amazon.com/eks/latest/userguide/windows-support.html#enable-windows-support
  iam_role_additional_policies = {
    "eks-vpc-resource-access" = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  }

  # Needed to add self managed node group configuration.
  manage_aws_auth_configmap = true

  # Linux Node Groups
  eks_managed_node_groups = {
    "linux-workers" = {
      ami_type       = "AL2_x86_64"   # Amazon Linux 2
      instance_types = ["t3a.xlarge"] # 4 AMD vCPUs, 16GiB RAM, 5Gi Network

      min_size     = 2
      desired_size = 2
      max_size     = 10
    }
  }

  # Windows Node Groups
  # Note: EKS does not support EKS managed node groups for Windows nodes.
  self_managed_node_groups = {
    "windows-2019-workers" = {
      platform      = "windows"
      ami_id        = data.aws_ami.eks_windows_2019.image_id
      instance_type = "t3a.xlarge" # 4 AMD vCPUs, 16GiB RAM, 5Gi Network

      min_size     = 2
      desired_size = 2
      max_size     = 10
    }
  }
}

# Configure the Amazon VPC CNI to support Windows IPAM.
# See: https://docs.aws.amazon.com/eks/latest/userguide/windows-support.html#enable-windows-support
resource "kubernetes_config_map" "amazon_vpc_cni" {
  metadata {
    name      = "amazon-vpc-cni"
    namespace = "kube-system"
  }

  data = {
    enable-windows-ipam = "true"
  }
}

# Latest Amazon Windows EKS Node Image
data "aws_ami" "eks_windows_2019" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Core-EKS_Optimized-${local.cluster_version}-*"]
  }
}
