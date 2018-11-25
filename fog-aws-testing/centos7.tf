
resource "aws_instance" "centos7" {
  ami           = "${var.amis["centos7"]}"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.private-subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.allow-bastion.id}"]
  associate_public_ip_address = false
  key_name = "${aws_key_pair.ssh-key.key_name}"
  connection {
    type     = "ssh"
    user     = "centos"
    private_key = "${file("/root/.ssh/fogtesting_private")}"
    bastion_host = "${aws_instance.bastion.public_ip}"
    bastion_user = "admin"
    bastion_private_key = "${file("/root/.ssh/fogtesting_private")}"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo yum -y update",
      "sudo sed -i '/PermitRootLogin/d' /etc/ssh/sshd_config",
      "sudo echo 'PermitRootLogin prohibit-password' >> /etc/ssh/sshd_config",
      "sudo mkdir -p /root/.ssh",
      "sudo cp /home/ec2-user/.ssh/authorized_keys /root/.ssh/authorized_keys",
      "sudo yum -y install git",
      "sudo mkdir -p /root/git",
      "sudo git clone https://github.com/FOGProject/fogproject /root/git/fogproject",
      "sudo sed -i '/SELINUX=enforcing/d' /etc/selinux/config",
      "sudo echo 'SELINUX=permissive' >> /etc/selinux/config",
      "(sleep 10 && sudo reboot)&"
    ]
  }
  tags {
    Name = "${var.project}-centos7"
    Project = "${var.project}"
    OS = "centos7"
  }
  depends_on = ["aws_route_table_association.private-route-table-association"]
}
resource "aws_route53_record" "centos7-dns-record" {
  zone_id = "${aws_route53_zone.private-zone.zone_id}"
  name    = "centos7.fogtesting.cloud"
  type    = "CNAME"
  ttl     = "300"
  records = ["${aws_instance.centos7.private_dns}"]
}




