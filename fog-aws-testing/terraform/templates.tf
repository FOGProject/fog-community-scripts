data "template_file" "ssh-config" {
  template = "${file("templates/ssh-config.tpl")}"
}


data "template_file" "aws-config" {
  template = "${file("templates/aws-config.tpl")}"
  vars = {
    region = "${var.region}"
  }
}

