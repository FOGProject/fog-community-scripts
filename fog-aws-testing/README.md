## FOG AWS Tests

This is FOG's automated installation tests, and is subject to the fog-community-scripts license in the root of the fog-community-scripts repository.

This project aims to reliably and consistently test the FOG Installation process against many different Linux distributions in an automated fashion. Each test aims to use said Linux distribution's very latest patches. This is so problems with the FOG Installation process are caught early and addressed, and so new releases of Linux Distributions can be supported more easily.

Some things to note about this project:

 - This project uses Amazon Web Services to perform all testing, automatically, every day.
 - This project uses Terraform to manage all infrastructure used in these tests.
 - This project requires a pre-existing public hosted zone within Route53. This is used to create DNS records and s3 bucket names, and to publish test results.
 - The testing tools are written mostly in Python 2.
 - There's some BASH in use where appropriate.
 - This project needs it's own SSH key-pair to function, and your public SSH key for you to access the bastion server.

To start using this project to run FOG Tests for yourself:

 - You need an AWS account.
 - You need a public hosted zone that you own in Route53.
 - You need Terraform installed on your local system.
 - Clone this repository to your local system.
 - If you're new to this, you'll find a file in the repository called `source_me.sh`. Copy this file to somewhere outside of the repository directory. This is so you don't accidentally commit your API keys. Place a copy of your AWS API keys into your personal copy of the `source_me.sh` script. Then run the command `source source_me.sh`.
 - Go into the `terraform` directory.
 - Look over the `variables.tf` file and input your public hosted zone's `zone_name` and `zone_id`. Also enter in the s3 bucket name where you wish to keep Terraform's remote state files. It's the section titled `terraform { backend "s3" {
bucket =` 
 - **SSH**:  This project assumes an SSH key-pair is available exclusively for this project, as well as the public copy of your personal key for entering into the bastion server. 
 - The **project** ssh public and private paths are defined inside of `ssh_keys.tf`. A copy of the private key is placed on the bastion server, and the public key is placed into `authorized_keys` for all instances in the infrastructure.
 - A copy of your personal SSH **public** key should be put in `ssh_keys.tf` as text. This enables you to use your personal SSH keys to access the bastion, and then use the project's keys to access everything else from the bastion.
 - Run `terraform apply` and inspect the plans, type `yes` if they look good.
 - Wait for all necessary infrastructure to be provisioned. This can take a long time because all OSs are fully patched in this process.
 - Once done, you should be able to ssh into the bastion. It's public DNS record can be found in Route53, but should be `fogbastion.YourDomain`.
 - From here, you should find a copy of the fog-community-scripts repository within your home directory. Navigate into the `fog-community-scripts/fog-aws-testing/scripts` directory.
 - From here, you should be able to run the available scripts. Permissions are inherited from an instance role created for you by Terraform.
 - You'll need to edit the `settings.py` file with the correct s3 bucket name - this is the bucket used to host test results.
 - Next, you need to create clean snapshots of all the test OSs. There's a script for this called `create_clean_snapshots.py`.
 - From here, tests will run regularly via a cron-job.
 - You can manually run tests with the `test_all.py` script.


