output "vpc_a_id" {
  description = "VPC A ID."
  value       = aws_vpc.vpc_a.id
}

output "vpc_b_id" {
  description = "VPC B ID."
  value       = aws_vpc.vpc_b.id
}

output "vpc_peering_connection_id" {
  description = "VPC peering connection ID between A and B."
  value       = aws_vpc_peering_connection.a_to_b.id
}

output "instance_a_public_ip" {
  description = "Public IP of EC2 in VPC A."
  value       = aws_eip.eip_a.public_ip
}

output "instance_b1_public_ip" {
  description = "Public IP of EC2 B1 in VPC B."
  value       = aws_eip.eip_b1.public_ip
}

output "instance_b2_public_ip" {
  description = "Public IP of EC2 B2 in VPC B."
  value       = aws_eip.eip_b2.public_ip
}

output "instance_a_private_ip" {
  description = "Private IP of EC2 A."
  value       = aws_network_interface.eni_a.private_ip
}

output "instance_b1_private_ip" {
  description = "Private IP of EC2 B1."
  value       = aws_network_interface.eni_b1.private_ip
}

output "instance_b2_private_ip" {
  description = "Private IP of EC2 B2."
  value       = aws_network_interface.eni_b2.private_ip
}
