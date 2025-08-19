terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# EKS Cluster for DevOps
module "devops_cluster" {
  source = "terraform-aws-modules/eks/aws"
  
  cluster_name    = "devops-cluster"
  cluster_version = "1.28"
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  
  eks_managed_node_groups = {
    devops_nodes = {
      min_size     = 2
      max_size     = 5
      desired_size = 3
      
      instance_types = ["t3.medium"]
      
      labels = {
        cluster = "devops"
        role    = "monitoring"
      }
    }
  }
  
  tags = {
    Environment = "production"
    Purpose     = "monitoring"
  }
}

# EKS Cluster for Applications
module "application_cluster" {
  source = "terraform-aws-modules/eks/aws"
  
  cluster_name    = "application-cluster"
  cluster_version = "1.28"
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  
  eks_managed_node_groups = {
    app_nodes = {
      min_size     = 3
      max_size     = 10
      desired_size = 5
      
      instance_types = ["t3.large"]
      
      labels = {
        cluster = "application"
        role    = "workload"
      }
    }
  }
  
  tags = {
    Environment = "production"
    Purpose     = "applications"
  }
}