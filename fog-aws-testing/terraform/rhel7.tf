
resource "aws_instance" "rhel7" {
  ami           = "${var.amis["rhel7"]}"
  instance_type = "t3.micro"
  subnet_id = "${aws_subnet.public-subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.allow-bastion.id}"]
  associate_public_ip_address = true
  key_name = "${aws_key_pair.ssh-key.key_name}"
  root_block_device {
    volume_type = "standard"
    volume_size = 10
    delete_on_termination = true
  }
  connection {
    type     = "ssh"
    user     = "ec2-user"
    host     = "${aws_instance.rhel7.private_ip}"
    private_key = "${file("/root/.ssh/fogtesting_private")}"
    bastion_host = "${aws_instance.bastion.public_ip}"
    bastion_user = "admin"
    bastion_private_key = "${file("/root/.ssh/fogtesting_private")}"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo setenforce 0",
      "sudo sed -i '/PermitRootLogin/d' /etc/ssh/sshd_config",
      "echo 'PermitRootLogin prohibit-password' | sudo tee --append /etc/ssh/sshd_config",
      "sudo mkdir -p /root/.ssh",
      "sudo cp /home/ec2-user/.ssh/authorized_keys /root/.ssh/authorized_keys",
      "# sudo sed -i '/SELINUX=enforcing/d' /etc/selinux/config",
      "# echo 'SELINUX=permissive' | sudo tee --append /etc/selinux/config",
      "sudo mkdir -p /root/git",
      "sudo yum -y install git",
      "sudo git clone ${var.fog-project-repo} /root/git/fogproject",
      "sudo yum -y update",
      "(sleep 10 && sudo reboot)&"
    ]
  }
  tags {
    Name = "${var.project}-rhel7"
    Project = "${var.project}"
    OS = "rhel7"
  }
}

resource "aws_route53_record" "rhel7-dns-record" {
  zone_id = "${aws_route53_zone.private-zone.zone_id}"
  name    = "rhel7.fogtesting.cloud"
  type    = "CNAME"
  ttl     = "300"
  records = ["${aws_instance.rhel7.private_dns}"]
}




