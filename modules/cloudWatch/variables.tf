variable "project_name" {
  description = "Project name for tagging"
  type        = string
}

variable "eks_cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "node_group_name" {
  description = "EKS node group name"
  type        = string
}
