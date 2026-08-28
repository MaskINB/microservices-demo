module "vpc" {
  source = "./modules/vpc"

  project_name = "induwara-eks-platform"
  vpc_cidr     = "10.0.0.0/16"

  tags = {
    Project     = "eks-microservices-platform"
    Environment = "portfolio"
    ManagedBy   = "terraform"
  }
}

# Each of these 11 services needs its own container registry repository, so images get built, tagged, and pulled independently per service.

module "ecr" {
  source = "./modules/ecr"

  repository_names = [
    "adservice",
    "cartservice",
    "checkoutservice",
    "currencyservice",
    "emailservice",
    "frontend",
    "loadgenerator",
    "paymentservice",
    "productcatalogservice",
    "recommendationservice",
    "shippingservice",
    "shoppingassistantservice"
  ]

  tags = {
    Project     = "eks-microservices-platform"
    Environment = "portfolio"
    ManagedBy   = "terraform"
  }
}

#IAM roles for the EKS cluster and its node groups. The cluster role is assumed by the EKS service, while the node role is assumed by EC2 instances in the node group. Each role has the necessary policies attached to allow proper operation of the EKS cluster and its nodes.

module "iam" {
  source = "./modules/iam"

  cluster_name = "induwara-eks-platform"

  tags = {
    Project     = "eks-microservices-platform"
    Environment = "portfolio"
    ManagedBy   = "terraform"
  }
}

#EKS to deploy the microservices platform. The EKS module is configured to use the VPC and IAM roles created in the previous modules, and it sets up a managed node group with specific instance types and capacity settings.

module "eks" {
  source = "./modules/eks"

  cluster_name        = "induwara-eks-platform"
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  cluster_role_arn    = module.iam.cluster_role_arn
  node_role_arn       = module.iam.node_role_arn

  tags = {
    Project     = "eks-microservices-platform"
    Environment = "portfolio"
    ManagedBy   = "terraform"
  }
}