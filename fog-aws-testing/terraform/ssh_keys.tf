# This is used to create an AWS key-pair resource for use in provisioning all the OSs.
# We specify the path to it because it is not included in the repository.
resource "aws_key_pair" "ssh-key" {
  key_name   = "fogtesting"
  public_key = file("~/.ssh/fogtesting_public")
}

# This is the private key for the above public key.
# We specify the path to it because it is not included in the repository.
# This file is uploaded to the bastion server, and is used to issue commands to all the test OSs.
variable "private_key_path" {
  default = "~/.ssh/fogtesting_private"
}


