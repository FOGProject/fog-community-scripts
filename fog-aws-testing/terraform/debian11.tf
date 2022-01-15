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

  user_data = <<END_OF_USERDATA
#!/bin/bash
apt-get update
apt-get -y dist-upgrade
sed -i '/PermitRootLogin/d' /etc/ssh/sshd_config
echo '' >> /etc/ssh/sshd_config
echo 'PermitRootLogin prohibit-password' >> /etc/ssh/sshd_config
mkdir -p /root/.ssh
cp /home/admin/.ssh/authorized_keys /root/.ssh/authorized_keys
apt-get -y install git
mkdir -p /root/git
git clone ${var.fog-project-repo} /root/git/fogproject
(sleep 10 && sudo reboot)&
END_OF_USERDATA

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

