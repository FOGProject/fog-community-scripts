resource "aws_instance" "rhel7" {
  count                       = var.make_instances
  ami                         = data.aws_ami.rhel7.id
  instance_type               = "t3.small"
  subnet_id                   = aws_subnet.public-subnet.id
  vpc_security_group_ids      = [aws_security_group.allow-bastion[0].id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.ssh-key.key_name
  root_block_device {
    volume_type           = "standard"
    volume_size           = 10
    delete_on_termination = true
  }

  user_data = <<END_OF_USERDATA
#!/bin/bash
setenforce 0
sed -i '/PermitRootLogin/d' /etc/ssh/sshd_config
echo '' | sudo tee --append /etc/ssh/sshd_config
echo 'PermitRootLogin prohibit-password' | tee --append /etc/ssh/sshd_config
sudo mkdir -p /root/.ssh
sudo cp /home/ec2-user/.ssh/authorized_keys /root/.ssh/authorized_keys
# sed -i '/SELINUX=enforcing/d' /etc/selinux/config
# echo 'SELINUX=permissive' | tee --append /etc/selinux/config
mkdir -p /root/git
yum -y install git
git clone ${var.fog-project-repo} /root/git/fogproject
yum -y update
(sleep 10 && sudo reboot)&
END_OF_USERDATA

  tags = {
    Name    = "${var.project}-rhel7"
    Project = var.project
    OS      = "rhel7"
  }
}

resource "aws_route53_record" "rhel7-dns-record" {
  count   = var.make_instances
  zone_id = aws_route53_zone.private-zone.zone_id
  name    = "rhel7.fogtesting.cloud"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_instance.rhel7[0].private_dns]
}

