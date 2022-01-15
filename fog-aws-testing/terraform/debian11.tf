resource "aws_instance" "debian11" {
  count                       = var.make_instances
  ami                         = data.aws_ami.debian11.id
  instance_type               = "t3.micro"
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
    user                = "admin"
    host                = aws_instance.debian11[0].private_ip
    private_key         = file("~/.ssh/fogtesting_private")
    bastion_host        = aws_instance.bastion[0].public_ip
    bastion_user        = "admin"
    bastion_private_key = file("~/.ssh/fogtesting_private")
  }
  provisioner "remote-exec" {
    #on_failure = continue
    inline = [
      "sudo apt-get update",
      "sudo apt-get -y dist-upgrade",
      "sudo sed -i '/PermitRootLogin/d' /etc/ssh/sshd_config",
      "sudo echo '' >> /etc/ssh/sshd_config",
      "sudo echo 'PermitRootLogin prohibit-password' >> /etc/ssh/sshd_config",
      "sudo mkdir -p /root/.ssh",
      "sudo cp /home/admin/.ssh/authorized_keys /root/.ssh/authorized_keys",
      "sudo apt-get -y install git",
      "sudo mkdir -p /root/git",
      "sudo git clone ${var.fog-project-repo} /root/git/fogproject",
      "(sleep 10 && sudo reboot)&",
    ]
  }
  tags = {
    Name    = "${var.project}-debian11"
    Project = var.project
    OS      = "debian11"
  }
}

resource "aws_route53_record" "debian11-dns-record" {
  count   = var.make_instances
  zone_id = aws_route53_zone.private-zone.zone_id
  name    = "debian11.fogtesting.cloud"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_instance.debian11[0].private_dns]
}

