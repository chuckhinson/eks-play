variable "project_name" {
  nullable = false
  description = "The cluster name - will be used in the names of all resources.  This must be the cluster name as provided to kubespray in order for the cloud-controller manager to work properly"
}

variable "subnet_ids" {
  type = list(string)
  description = "Identifiers of EC2 Subnets to associate with the EKS Node Group"
}

variable "cluster_security_group_id" {
  type = string
  description = "This should be the control plane cluster security group id"
}

variable "remote_ssh_cdir_block" {
  type = string
  description = "CIDR block from which to allow ssh connections to nodes"
}

variable "node_keypair_name" {
  type = string
  description = "Name of keypair to be used for ssh access to nodes"
}
