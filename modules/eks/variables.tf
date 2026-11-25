variable "cluster_name" {
  type = string
}

variable "kubernetes_version" {
  type = string
}

variable "subnet_ids" {
  description = "Private subnets for the cluster and nodes."
  type        = list(string)
}

variable "endpoint_public_access" {
  description = "Expose the API server publicly (needed for kubectl from your laptop / GitHub runners)."
  type        = bool
  default     = true
}

variable "ami_type" {
  type    = string
  default = "AL2023_x86_64_STANDARD"
}

variable "enable_oidc" {
  description = "Create the IAM OIDC provider for IRSA."
  type        = bool
  default     = true
}

variable "addons" {
  type    = list(string)
  default = ["vpc-cni", "kube-proxy", "coredns", "eks-pod-identity-agent"]
}

variable "admin_principal_arns" {
  description = "IAM user/role ARNs that get cluster admin access."
  type        = list(string)
  default     = []
}

variable "system_node_group" {
  type = object({
    name           = string
    instance_types = list(string)
    desired_size   = number
    min_size       = number
    max_size       = number
    disk_size      = number
  })
}

variable "user_node_group" {
  type = object({
    name           = string
    instance_types = list(string)
    desired_size   = number
    min_size       = number
    max_size       = number
    disk_size      = number
  })
}

variable "tags" {
  type    = map(string)
  default = {}
}
