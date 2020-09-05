output "fqdn" {
  value = aws_route53_record.record.fqdn
}
output "public_ip" {
  value = aws_eip.eip.public_ip
}
