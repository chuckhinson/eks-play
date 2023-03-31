output "project_name" {
  value = var.project_name
}

output "aws_profile_name" {
  value = var.aws_profile_name
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet1" {
  value = module.vpc.public_subnet1
}

output "public_subnet2" {
  value = module.vpc.public_subnet2
}

output "private_subnet1" {
  value = module.vpc.private_subnet1
}

output "private_subnet2" {
  value = module.vpc.private_subnet2
}

output "ssh_private_key" {
  value = module.vpc.ssh_private_key
  sensitive = true
}

output "jumpbox_public_ip" {
  value = module.vpc.jumpbox_public_ip
}
