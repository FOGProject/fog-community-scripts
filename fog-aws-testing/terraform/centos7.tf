resource "aws_instance" "centos7" {
  count                       = var.make_instances
  ami                         = data.aws_ami.centos7.id
  instance_type               = "t2.small"
  subnet_id                   = aws_subnet.public-subnet.id
  vpc_security_group_ids      = [aws_security_group.allow-bastion[0].id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.ssh-key.key_name
  root_block_device {
    volume_type           = "standard"
    volume_size           = 8
    delete_on_termination = true
  }
  connection {
    type                = "ssh"
    user                = "centos"
    host                = aws_instance.centos7[0].private_ip
    private_key         = file("~/.ssh/fogtesting_private")
    bastion_host        = aws_instance.bastion[0].public_ip
    bastion_user        = "admin"
    bastion_private_key = file("~/.ssh/fogtesting_private")
  }
  provisioner "remote-exec" {
    #on_failure = continue
    inline = [
      "sudo setenforce 0",
      "sudo sed -i '/PermitRootLogin/d' /etc/ssh/sshd_config",
      "echo '' | sudo tee --append /etc/ssh/sshd_config",
      "echo 'PermitRootLogin prohibit-password' | sudo tee --append /etc/ssh/sshd_config",
      "sudo mkdir -p /root/.ssh",
      "sudo cp /home/centos/.ssh/authorized_keys /root/.ssh/authorized_keys",
      "# sudo sed -i '/SELINUX=enforcing/d' /etc/selinux/config",
      "# echo 'SELINUX=permissive' | sudo tee --append /etc/selinux/config",
      "sudo mkdir -p /root/git",
      "sudo yum -y install git",
      "sudo git clone ${var.fog-project-repo} /root/git/fogproject",
      "sudo yum -y update",
      "(sleep 10 && sudo reboot)&",
    ]
  }
  tags = {
    Name    = "${var.project}-centos7"
    Project = var.project
    OS      = "centos7"
  }
}

resource "aws_route53_record" "centos7-dns-record" {
  count   = var.make_instances
  zone_id = aws_route53_zone.private-zone.zone_id
  name    = "centos7.fogtesting.cloud"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_instance.centos7[0].private_dns]
}

