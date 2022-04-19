### Author: Wayne Workman
---
This project is subject to the terms of the FOG Community Scripts license, found at the base of this repository.

"external_reporting" is a small project collects version information reported by FOG systems. You will find the Terraform here that creates the infrastructure as well as provisions the application used to collect the data.

If you are wanting to run this yourself, you will find some outputs are needed from a Terraform "base" layer. Things like subnet IDs, hosted zone IDs, VPC IDs, etc. First step would be to adjust the remote state to point to your own, and adjust the output usage to be your own, or replace these with variables.

Second step is to run the terraform. This should provision a small instance and an s3 bucket, some security groups, some IAM profiles & policies. The Terraform will initiate the software installation via UserData. A certificate is obtained from Let's Encrypt automatically via userdata.

To run without the Terraform, you'll find an installer within the application that works with Debian 10.


## DB Restore Procedures

Using terminal on the reporting API instance (ssh or session manager), copy the latest DB backup from s3:

`aws s3 cp s3://fog-external-reporting-results.theworkmans.us/db.tar.gz .`

Unpack the tar file:
`tar -xf db.tar.gz`

Load into MariaDB:
`mysql -D external_reporting < db.sql`


