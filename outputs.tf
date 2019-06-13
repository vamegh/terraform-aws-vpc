output "vpc_id" {
  description = "The id of the VPC."
  value = aws_vpc.main[0].id
}

output "vpc_cidr" {
  description = "The CDIR block used for the VPC."
  value       = aws_vpc.main[0].cidr_block
}

output "public_subnets" {
  description = "A list of the public subnets."
  value       = aws_subnet.public.*.id
}

output "private_subnets" {
  description = "A list of the private subnets."
  value       = aws_subnet.private.*.id
}
