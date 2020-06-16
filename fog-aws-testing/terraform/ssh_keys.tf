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
  default = "/root/.ssh/fogtesting_private"
}

# This is your personal SSH public key.
# This is ADDED to /home/admin/.ssh/authorized_users in addition to the above public key.
# This is so you can use your personal ssh key to get into the bastion itself, and then use the project key for all other OSs which is already loaded onto the bastion.
variable "waynes-key" {
  type    = string
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCyoAB+Q71T5ItCKAIfCAP0ybuv9uDkMHS8f/T4ygYJ5bIsiEG47SGBXmkg5DVKomWMMdfJae65Y7gpLlclj5t4Ra4oVWX3Bx7AcAJ6ec8RpeubcNep4fDaSfD7RSPwx9cnOfKXf1rs2DUPHOykvnQeSfbczfoM2lCmPUGHTgrSkK0z9wiNSCpuu6T1MrESaMIjRHmAQjD/y+Gq+hvW6X58UkXnB3bnZNFoy3ahtDDIqafzs7LMNHw4vjtV20OTI66M4y/J4BR02a0lAZ+IUr9izig0z7/OFUD1iIHXPv3h5hO9z/w9njj4jGbCUdvrSUsw7DSZv7u5mSElgmUaIOp/eBmX4l2g3WtatgOwnnA+7RNtbGtD0QwO8q0FI3atpDUGHl3E9nFWAnxO/9oLzGglBZYDxZchzu0dxLixygqRuBgt67C6UBspCOHFiKwJcZtcVjioSTqQisbK8RBaRxoF43GmtoOchW6x3aubyhJEqISGn+9sBwMb93/Q/Qv0AsCoxsRwxdpXUs+h5UdduRZjya8SiK323cMZlRm0vuhN8kcGwtyNznLcb9RrlmmMd7pmBJGvfursqONYH+mhdr0wXR4sY3KtrRnaqkuSbymw0vQmKWmcw2v8vypkYuSvosNM99wAd/vfpiBSarC6tAtcf7nfNY1F0JQH1nJp2bIZgQ== wayne@r0291507869LLMB"
}

