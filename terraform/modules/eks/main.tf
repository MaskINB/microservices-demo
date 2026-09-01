module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  create_iam_role = false
  iam_role_arn    = var.cluster_role_arn

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  enable_cluster_creator_admin_permissions = true # ← add this line

  eks_managed_node_groups = {
    default = {
      create_iam_role = false
      iam_role_arn    = var.node_role_arn

      instance_types = ["t3.medium"]
      capacity_type  = "SPOT"

      min_size     = 2
      max_size     = 4
      desired_size = 2
    }
  }

  tags = var.tags
}