output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.ctops-vpc.id
}

output "public_subnets" {
  description = "List of IDs of Public subnets"
  value       = aws_subnet.ctops-public-subnet[*].id
}


output "private_subnets" {
  description = "List of IDs of private subnets"
  value = try(aws_subnet.ctops-private-subnet[*].id, null )
}