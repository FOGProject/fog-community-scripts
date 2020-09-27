output "entries_fqdn" {
  value = aws_route53_record.record.fqdn
}
output "entries_public_ip" {
  value = aws_eip.eip.public_ip
}
