
output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet1" {
  value = aws_subnet.public1.id
}

output "public_subnet2" {
  value = aws_subnet.public2.id
}

output "private_subnet1" {
  value = aws_subnet.private1.id
}

output "private_subnet2" {
  value = aws_subnet.private2.id
}

output "ssh_keypair_name" {
  value = aws_key_pair.ec2_keypair.key_name
}

output "ssh_private_key" {
  value = tls_private_key.ssh_key.private_key_pem
  sensitive = true
}

output "jumpbox_instance_id" {
  value = aws_instance.jumpbox.id
}