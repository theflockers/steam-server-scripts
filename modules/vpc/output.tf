output "subnet_a_id" { value =  "${aws_subnet.a.id}" }
output "subnet_b_id" { value =  "${aws_subnet.b.id}" }
output "subnet_c_id" { value =  "${aws_subnet.c.id}" }
output "subnets"     { 
  value = 
  [
    "${aws_subnet.a.id}",
    "${aws_subnet.b.id}",
    "${aws_subnet.c.id}" 
  ] 
}
output "vpc_id"      { value =  "${aws_vpc.vpc.id}" }
