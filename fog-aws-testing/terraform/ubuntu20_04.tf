resource "aws_instance" "ubuntu20_04" {
  count                       = var.make_instances
  ami                         = data.aws_ami.ubuntu20.id
  instance_type               = "t3.small"
  subnet_id                   = aws_subnet.public-subnet.id
  vpc_security_group_ids      = [aws_security_group.allow-bastion[0].id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.ssh-key.key_name
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    delete_on_termination = true
    tags = {
      Name    = "${var.project}-ubuntu20_04"
      Project = var.project
      OS      = "ubuntu20_04"
    }
  }

  tags = {
    Name    = "${var.project}-ubuntu20_04"
    Project = var.project
    OS      = "ubuntu20_04"
  }
  lifecycle {
    ignore_changes = [
      associate_public_ip_address, ami, root_block_device[0].volume_type,
    ]
  }

  user_data = <<END_OF_USERDATA
#!/bin/bash
apt-get -y remove unattended-upgrades
apt-get update
apt-get -y upgrade
sed -i '/PermitRootLogin/d' /etc/ssh/sshd_config
echo '' >> /etc/ssh/sshd_config
echo 'PermitRootLogin prohibit-password' >> /etc/ssh/sshd_config
mkdir -p /root/.ssh
cp /home/ubuntu/.ssh/authorized_keys /root/.ssh/authorized_keys
apt-get -y install git
mkdir -p /root/git
git clone ${var.fog-project-repo} /root/git/fogproject
(sleep 10 && sudo reboot)&
END_OF_USERDATA
}

resource "aws_route53_record" "ubuntu20_04-dns-record" {
  count   = var.make_instances
  zone_id = aws_route53_zone.private-zone.zone_id
  name    = "ubuntu20_04.fogtesting.cloud"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_instance.ubuntu20_04[0].private_dns]
}

