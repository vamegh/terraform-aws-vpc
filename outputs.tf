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

output "internal_subnets" {
  description = "A list of the internal subnets."
  value       = aws_subnet.internal.*.id
}

output "private_subnets" {
  description = "A list of the private subnets."
  value       = aws_subnet.private.*.id
}

output "database_subnets" {
  description = "A list of the database subnets."
  value       = aws_subnet.database.*.id
}

output "redshift_subnets" {
  description = "A list of the redshift subnets."
  value       = aws_subnet.redshift.*.id
}
