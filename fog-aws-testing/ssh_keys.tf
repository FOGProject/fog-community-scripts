resource "aws_key_pair" "ssh-key" {
  key_name   = "fogtesting"
  public_key = "${file("/root/.ssh/fogtesting_public")}"
}


variable "waynes-key" {
    type = "string"
    default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCyoAB+Q71T5ItCKAIfCAP0ybuv9uDkMHS8f/T4ygYJ5bIsiEG47SGBXmkg5DVKomWMMdfJae65Y7gpLlclj5t4Ra4oVWX3Bx7AcAJ6ec8RpeubcNep4fDaSfD7RSPwx9cnOfKXf1rs2DUPHOykvnQeSfbczfoM2lCmPUGHTgrSkK0z9wiNSCpuu6T1MrESaMIjRHmAQjD/y+Gq+hvW6X58UkXnB3bnZNFoy3ahtDDIqafzs7LMNHw4vjtV20OTI66M4y/J4BR02a0lAZ+IUr9izig0z7/OFUD1iIHXPv3h5hO9z/w9njj4jGbCUdvrSUsw7DSZv7u5mSElgmUaIOp/eBmX4l2g3WtatgOwnnA+7RNtbGtD0QwO8q0FI3atpDUGHl3E9nFWAnxO/9oLzGglBZYDxZchzu0dxLixygqRuBgt67C6UBspCOHFiKwJcZtcVjioSTqQisbK8RBaRxoF43GmtoOchW6x3aubyhJEqISGn+9sBwMb93/Q/Qv0AsCoxsRwxdpXUs+h5UdduRZjya8SiK323cMZlRm0vuhN8kcGwtyNznLcb9RrlmmMd7pmBJGvfursqONYH+mhdr0wXR4sY3KtrRnaqkuSbymw0vQmKWmcw2v8vypkYuSvosNM99wAd/vfpiBSarC6tAtcf7nfNY1F0JQH1nJp2bIZgQ== wayne@r0291507869LLMB"
}


