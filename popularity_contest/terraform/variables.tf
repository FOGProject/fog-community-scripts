variable "name" {
  type = string
  default = "fog-popularity-contest"
  description = "Name used for resources, must be URL naming compliant"
}


variable "my_public_ip_cidr" {
  type = string
  default = "75.60.134.203/32"
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
