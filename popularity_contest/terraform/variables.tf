variable "entries_name" {
  type = string
  default = "fog-popularity-entries"
  description = "Name used for resources, must be URL naming compliant"
}

variable "results_name" {
  type = string
  default = "fog-popularity-results"
  description = "Name used for result resources, must be URL naming compliant"
}

variable "project" {
  type = string
  default = "fog-popularity"
  description = "Project name"
}


data "http" "public_ip" {
  # This is to get the public IP of the system executing this TF, rather than hardcoding it in the code-base.
  # The public IP is used in the security group for locking-down port 22 for SSH.
  url = "https://ipinfo.io/json"
  # Backup:
  #url = "https://ifconfig.co/json"
  request_headers = {
    Accept = "application/json"
  }
}


variable "instance_type" {
  type = string
  default = "t3.nano"
}

data "aws_ami" "debian10" {
  most_recent = true
  owners      = ["136693071363"]
  filter {
    name   = "name"
    values = ["debian-10-amd64-*"]
  }
}


