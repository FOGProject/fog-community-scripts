resource "aws_instance" "fedora35" {
  count                       = var.make_instances
  ami                         = data.aws_ami.fedora35.id
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
      Name    = "${var.project}-fedora35"
      Project = var.project
      OS      = "fedora35"
    }
  }

  tags = {
    Name    = "${var.project}-fedora35"
    Project = var.project
    OS      = "fedora35"
  }
  lifecycle {
    ignore_changes = [
      associate_public_ip_address, ami, root_block_device[0].volume_type,
    ]
  }

  user_data = <<END_OF_USERDATA
#!/bin/bash
sudo setenforce 0
sed -i '/PermitRootLogin/d' /etc/ssh/sshd_config
echo '' | tee --append /etc/ssh/sshd_config
echo 'PermitRootLogin prohibit-password' | tee --append /etc/ssh/sshd_config
mkdir -p /root/.ssh
cp /home/fedora/.ssh/authorized_keys /root/.ssh/authorized_keys
# sed -i '/SELINUX=enforcing/d' /etc/selinux/config
# echo 'SELINUX=permissive' | tee --append /etc/selinux/config
mkdir -p /root/git
dnf -y install git
git clone ${var.fog-project-repo} /root/git/fogproject
dnf -y update
(sleep 10 && sudo reboot)&
END_OF_USERDATA
}

resource "aws_route53_record" "fedora35-dns-record" {
  count   = var.make_instances
  zone_id = aws_route53_zone.private-zone.zone_id
  name    = "fedora35.fogtesting.cloud"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_instance.fedora35[0].private_dns]
}

