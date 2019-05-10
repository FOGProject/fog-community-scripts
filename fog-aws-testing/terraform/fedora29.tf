
resource "aws_instance" "fedora29" {
  ami           = "${data.aws_ami.fedora29.id}"
  instance_type = "t3.micro"
  subnet_id = "${aws_subnet.public-subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.allow-bastion.id}"]
  associate_public_ip_address = true
  key_name = "${aws_key_pair.ssh-key.key_name}"
  root_block_device {
    volume_type = "standard"
    volume_size = 6
    delete_on_termination = true
  }
  connection {
    type     = "ssh"
    user     = "fedora"
    host     = "${aws_instance.fedora29.private_ip}"
    private_key = "${file("/root/.ssh/fogtesting_private")}"
    bastion_host = "${aws_instance.bastion.public_ip}"
    bastion_user = "admin"
    bastion_private_key = "${file("/root/.ssh/fogtesting_private")}"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo setenforce 0",
      "sudo sed -i '/PermitRootLogin/d' /etc/ssh/sshd_config",
      "echo '' | sudo tee --append /etc/ssh/sshd_config",
      "echo 'PermitRootLogin prohibit-password' | sudo tee --append /etc/ssh/sshd_config",
      "sudo mkdir -p /root/.ssh",
      "sudo cp /home/fedora/.ssh/authorized_keys /root/.ssh/authorized_keys",
      "# sudo sed -i '/SELINUX=enforcing/d' /etc/selinux/config",
      "# echo 'SELINUX=permissive' | sudo tee --append /etc/selinux/config",
      "sudo mkdir -p /root/git",
      "sudo dnf -y install git",
      "sudo git clone ${var.fog-project-repo} /root/git/fogproject",
      "sudo dnf -y update",
      "(sleep 10 && sudo reboot)&"
    ]
  }
  tags {
    Name = "${var.project}-fedora29"
    Project = "${var.project}"
    OS = "fedora29"
  }
}

resource "aws_route53_record" "fedora29-dns-record" {
  zone_id = "${aws_route53_zone.private-zone.zone_id}"
  name    = "fedora29.fogtesting.cloud"
  type    = "CNAME"
  ttl     = "300"
  records = ["${aws_instance.fedora29.private_dns}"]
}




