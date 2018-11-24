
resource "aws_instance" "debian9" {
  ami           = "${var.amis["debian9"]}"
  instance_type = "t3.micro"
  subnet_id = "${aws_subnet.private-subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.sg-ssh.id}"]
  associate_public_ip_address = false
  key_name = "${aws_key_pair.ssh-key.key_name}"
  connection {
    type     = "ssh"
    user     = "admin"
    private_key = "${file("/root/.ssh/fogtesting_private")}"
    bastion_host = "${aws_instance.bastion.public_ip}"
    bastion_user = "admin"
    bastion_private_key = "${file("/root/.ssh/fogtesting_private")}"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get -y dist-upgrade",
      "sudo sed -i '/PermitRootLogin/d' /etc/ssh/sshd_config",
      "sudo echo 'PermitRootLogin prohibit-password' >> /etc/ssh/sshd_config",
      "sudo mkdir -p /root/.ssh",
      "sudo cp /home/admin/.ssh/authorized_keys /root/.ssh/authorized_keys",
      "sudo apt-get -y install git",
      "sudo mkdir -p /root/git",
      "sudo git clone https://github.com/FOGProject/fogproject /root/git/fogproject",
      "(sleep 10 && sudo reboot)&"
    ]
  }
  tags {
    Name = "${var.project}-debian9"
    Project = "${var.project}"
    OS = "debian9"
  }
}
resource "aws_route53_record" "debian9-dns-record" {
  zone_id = "${aws_route53_zone.private-zone.zone_id}"
  name    = "debian9.fogtesting.cloud"
  type    = "CNAME"
  ttl     = "300"
  records = ["${aws_instance.debian9.private_dns}"]
}




