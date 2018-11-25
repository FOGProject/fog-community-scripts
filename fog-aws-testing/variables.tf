# Backends cannot use interpolation.
terraform {
  backend "s3" {
    bucket = "remote-state.theworkmans.us"
    key    = "fogtesting.rs"
    region = "us-east-2"
  }
}

provider "aws" {
    region = "${var.region}"
}

variable "region" {
    type = "string"
    default = "us-east-2"
}

variable "project" {
    type = "string"
    default = "fogtesting"
}

variable "amis" {
  type    = "map"
  default = {
    "debian9" = "ami-08e2234d40f32eb5c"
    "centos7" = "ami-e1496384"
  }
}

variable "zone_id" {
    type = "string"
    default = "ZXXW1GUP5E4A0"
} 

variable "zone_name" {
    type = "string"
    default = "theworkmans.us"
} 


