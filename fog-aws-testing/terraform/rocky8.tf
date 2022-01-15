resource "aws_instance" "rocky8" {
  count                       = var.make_instances
  ami                         = data.aws_ami.rocky8.id
  instance_type               = "t3.small"
  subnet_id                   = aws_subnet.public-subnet.id
  vpc_security_group_ids      = [aws_security_group.allow-bastion[0].id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.ssh-key.key_name
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 10
    delete_on_termination = true
    tags = {
      Name    = "${var.project}-rocky8"
      Project = var.project
      OS      = "rocky8"
    }
  }

  tags = {
    Name    = "${var.project}-rocky8"
    Project = var.project
    OS      = "rocky8"
  }
  lifecycle {
    ignore_changes = [
      associate_public_ip_address, ami, root_block_device[0].volume_type,
    ]
  }

  user_data = <<END_OF_USERDATA
#!/bin/bash
setenforce 0
sed -i '/PermitRootLogin/d' /etc/ssh/sshd_config
echo '' | sudo tee --append /etc/ssh/sshd_config
echo 'PermitRootLogin prohibit-password' | tee --append /etc/ssh/sshd_config
mkdir -p /root/.ssh
rm -f /root/.ssh/authorized_keys
cp /home/rocky/.ssh/authorized_keys /root/.ssh/authorized_keys
# sed -i '/SELINUX=enforcing/d' /etc/selinux/config
# echo 'SELINUX=permissive' | tee --append /etc/selinux/config
mkdir -p /root/git
dnf -y install git
git clone ${var.fog-project-repo} /root/git/fogproject
dnf -y update
(sleep 10 && sudo reboot)&
END_OF_USERDATA
}

resource "aws_route53_record" "rocky8-dns-record" {
  count   = var.make_instances
  zone_id = aws_route53_zone.private-zone.zone_id
  name    = "rocky8.fogtesting.cloud"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_instance.rocky8[0].private_dns]
}

