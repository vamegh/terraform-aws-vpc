output "arn" {
  value = "${join("",aws_vpc.main.*.arn)}"
}

output "id" {
  value = "${join("",aws_vpc.main.*.id)}"
}
