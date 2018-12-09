# The list of OSs.
#OSs = ["debian9","centos7","rhel7","fedora29","arch","ubuntu18_04"]
OSs = ["arch","ubuntu18_04"]
#dnsAddresses = ["debian9.fogtesting.cloud","centos7.fogtesting.cloud","rhel7.fogtesting.cloud","fedora29.fogtesting.cloud","arch.fogtesting.cloud","ubuntu18_04.fogtesting.cloud"]
dnsAddresses = ["arch.fogtesting.cloud","ubuntu18_04.fogtesting.cloud"]

# The list of branches to process.
branches = ["master","dev-branch"]

# The region we operate in, dictated by terraform.
theRegion = "us-east-2"
# The availibility zone, which we use just one zone.
zone = theRegion + 'a'

# For when we need to wait for something to get done while in a loop, wait this long.
wait = 1

scriptDir = "/home/admin/fog-community-scripts/fog-aws-testing/scripts"

webdir = '/tmp/webdir'
statusDir = '/tmp/statuses'

indexHtml = 'index.html'

green = "green.png"
orange = "orange.png"
red = "red.png"

s3bucket = "fogtesting2.theworkmans.us"

http = "http://"
port = ""
netdir = ""

remoteResult = "/root/result"


ssh = "/usr/bin/ssh"
scp = "/usr/bin/scp"
timeout = "/usr/bin/timeout"
s3cmd = "/usr/bin/s3cmd"
ssh_keyscan = "/usr/bin/ssh-keyscan"


sshTimeout = "15"
fogTimeout= "15m" #Time to wait for FOG installation to complete. Must end with a unit of time. s for seconds, m for minutes.
sshTime="15s" #Time to wait for small SSH commands to complete. Must end with a unit of time. s for seconds, m for minutes.




codes = {
    "-1":{
        "reason":"Installer did not complete within alotted time.",
        "status":orange
    },
    "0":{
        "reason":"Success.",
        "status":green
    },
    "1":{
        "reason":"Failed to call script properly.",
        "status":orange
    },
    "2":{
        "reason":"Failed to reset git.",
        "status":orange
    },
    "3":{
        "reason":"Failed to pull git.",
        "status":orange
    },
    "4":{
        "reason":"Failed to checkout git.",
        "status":orange
    },
    "5":{
        "reason":"Failed to change directory.",
        "status":orange
    },
    "6":{
        "reason":"Installation failed.",
        "status":red
    }
}






