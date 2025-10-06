// Configure the AWS provider to use the us-east-1 region
provider "aws" {
  region = "us-east-1"
}

// Get information about the default VPC that already exists in your account.
// This avoids needing permissions to create a new VPC, which is ideal for limited IAM accounts.
data "aws_vpc" "default" {
  default = true
}

// Get information about the subnets within that default VPC.
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

// Use the official Terraform EKS module to create the Kubernetes Cluster.
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.3"

  cluster_name    = "my-app-cluster"
  cluster_version = "1.28"

  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnets.default.ids // Deploy the cluster across all default subnets

  // This defines the group of EC2 instances (worker nodes) that will run your application pods.
  eks_managed_node_groups = {
    main = {
      min_size     = 1
      max_size     = 2
      desired_size = 1
      instance_types = ["t3.medium"]
    }
  }
}

// Output the cluster name so Jenkins can easily use it.
output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

