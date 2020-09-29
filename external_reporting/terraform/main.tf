# Backends cannot use interpolation.
terraform {
  backend "s3" {
    bucket = "remote-state.theworkmans.us"
    key    = "foganalytics.rs"
    region = "us-east-2"
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  type    = string
  default = "us-east-2"
}

data "terraform_remote_state" "base" {
  backend = "s3"
  config = {
    bucket = "remote-state.theworkmans.us"
    key    = "home.rs"
    region = "us-east-2"
  }
}


