variable "name" {
  description = "Name of the ECR repository (lowercase)."
  type        = string
}
variable "image_tag_mutability" {
  type    = string
  default = "MUTABLE"
}
variable "scan_on_push" {
  type    = bool
  default = true
}
variable "force_delete" {
  description = "Allow destroy even when the repository still has images."
  type        = bool
  default     = true
}
variable "tags" {
  type    = map(string)
  default = {}
}
