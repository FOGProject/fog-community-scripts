
resource "aws_instance" "arch" {
  ami           = "${var.amis["arch"]}"
  instance_type = "t3.micro"
  subnet_id = "${aws_subnet.private-subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.allow-bastion.id}"]
  associate_public_ip_address = false
  key_name = "${aws_key_pair.ssh-key.key_name}"

  root_block_device {
    volume_type = "standard"
    volume_size = 8
    delete_on_termination = true
  }

  connection {
    type     = "ssh"
    user     = "root"
    private_key = "${file("/root/.ssh/fogtesting_private")}"
    bastion_host = "${aws_instance.bastion.public_ip}"
    bastion_user = "admin"
    bastion_private_key = "${file("/root/.ssh/fogtesting_private")}"
  }
  provisioner "remote-exec" {
    inline = [
      "pacman -Syu --noconfirm",
      "pacman -S git",
      "mkdir -p /root/git",
      "git clone https://github.com/FOGProject/fogproject /root/git/fogproject",
      "(sleep 10 && reboot)&"
    ]
  }
  tags {
    Name = "${var.project}-arch"
    Project = "${var.project}"
    OS = "arch"
  }
  depends_on = ["aws_route_table_association.private-route-table-association"]
}
resource "aws_route53_record" "arch-dns-record" {
  zone_id = "${aws_route53_zone.private-zone.zone_id}"
  name    = "arch.fogtesting.cloud"
  type    = "CNAME"
  ttl     = "300"
  records = ["${aws_instance.arch.private_dns}"]
}




