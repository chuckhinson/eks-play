variable "project_name" {
  nullable = false
  description = "The cluster name - will be used in the names of all resources.  This must be the cluster name as provided to kubespray in order for the cloud-controller manager to work properly"
}

variable "vpc_cidr_block" {
  default = "10.2.0.0/16"
}
