resource "aws_instance" "fedora35" {
  count                       = var.make_instances
  ami                         = data.aws_ami.fedora35.id
  instance_type               = "t3.small"
  subnet_id                   = aws_subnet.public-subnet.id
  vpc_security_group_ids      = [aws_security_group.allow-bastion[0].id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.ssh-key.key_name
  iam_instance_profile        = aws_iam_instance_profile.provisioning.name
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
output_log="/root/fedora35_provision_output.log"
dnf -y update >> $${output_log} 2>&1

# This bit here ensures we have python3, pip3, and the aws-cli.
# This is so the outcome of instance provisioning can be monitored easily via s3.
curl -sSL https://bootstrap.pypa.io/get-pip.py -o get-pip.py >> $${output_log} 2>&1
python3 get-pip.py >> $${output_log} 2>&1
pip3 install awscli >> $${output_log} 2>&1
aws s3 rm s3://${aws_s3_bucket.provisioning.id}/$${output_log} >> $${output_log} 2>&1

sudo setenforce 0 >> $${output_log} 2>&1
sed -i '/PermitRootLogin/d' /etc/ssh/sshd_config >> $${output_log} 2>&1
echo '' | tee --append /etc/ssh/sshd_config >> $${output_log} 2>&1
echo 'PermitRootLogin prohibit-password' | tee --append /etc/ssh/sshd_config >> $${output_log} 2>&1
mkdir -p /root/.ssh >> $${output_log} 2>&1
cp /home/fedora/.ssh/authorized_keys /root/.ssh/authorized_keys >> $${output_log} 2>&1
# sed -i '/SELINUX=enforcing/d' /etc/selinux/config >> $${output_log} 2>&1
# echo 'SELINUX=permissive' | tee --append /etc/selinux/config >> $${output_log} 2>&1
mkdir -p /root/git >> $${output_log} 2>&1
dnf -y install git >> $${output_log} 2>&1
git clone ${var.fog-project-repo} /root/git/fogproject >> $${output_log} 2>&1
(sleep 10 && sudo reboot)& >> $${output_log} 2>&1
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

