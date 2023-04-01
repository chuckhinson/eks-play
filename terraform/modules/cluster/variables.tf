variable "project_name" {
  nullable = false
  description = "The cluster name - will be used in the names of all resources.  This must be the cluster name as provided to kubespray in order for the cloud-controller manager to work properly"
}

variable "vpc_id" {
  nullable = false
  description = "The id of the vpc where the cluster's resources are to be created"
}

variable "subnet_ids" {
  type = list(string)
  description = "List of subnet ids for worker nodes"
}

variable "private_access_security_group_id" {
  type = string
  description = "Id of security group to be used by cluster to allow access to api endpoints"
}