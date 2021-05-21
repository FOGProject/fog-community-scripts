# The list of OSs.
OSs = ["debian10","centos7","centos8","rhel7","rhel8","fedora32","ubuntu18_04","ubuntu20_04"]
dnsAddresses = ["debian10.fogtesting.cloud","centos7.fogtesting.cloud","centos8.fogtesting.cloud","rhel7.fogtesting.cloud","rhel8.fogtesting.cloud","fedora32.fogtesting.cloud","ubuntu18_04.fogtesting.cloud","ubuntu20_04.fogtesting.cloud"]

# The list of branches to process.
#branches = ["master","dev-branch","working-1.6"]
branches = ["master","dev-branch"]

# The region we operate in, dictated by terraform.
theRegion = "us-east-1"
# The availibility zone, which we use just one zone.
zone = theRegion + 'a'

# Tags that get applied to all volumes and all snapshots that the scripts create.
globalTags = [
    {
        'Key': 'project',
        'Value': 'fogtesting'
    }
]


# For when we need to wait for something to get done while in a loop, wait this long.
wait = 1

scriptDir = "/home/admin/fog-community-scripts/fog-aws-testing/scripts"

webdir = '/tmp/webdir'
statusDir = '/tmp/statuses'

headerHtml = 'header.html'
footerHtml = 'footer.html'

green = "green.png"
orange = "orange.png"
red = "red.png"

s3bucket = "fogtesting.theworkmans.us"

http = "http://"
port = ""
netdir = ""

remoteResult = "/root/result"


ssh = "/usr/bin/ssh"
scp = "/usr/bin/scp"
timeout = "/usr/bin/timeout --foreground"
aws = "/usr/bin/aws"
ssh_keyscan = "/usr/bin/ssh-keyscan"


sshTimeout = "15" # used with the ssh ConnectTimeout option.
fogTimeout = "15m" # Time to wait for FOG installation to complete. Must end with a unit of time. s for seconds, m for minutes.
patchTimeout = "15m" # Time to wait for patching. Must end with a unit of time. s for seconds, m for minutes.
sshTime = "15s" # Time to wait for small SSH commands to complete. Must end with a unit of time. s for seconds, m for minutes.
bootTime = 90 # The time waited after an instance is brought up before commands are sent, and the time given for an instance to reboot.



codes = {
    "-1":{
        "reason":"Results were inconclusive.",
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
    },
    "7":{
        "reason":"Installation didn't complete within " + str(fogTimeout),
        "status":red
    }
}


