# The list of OSs.
OSs = ["debian9"]

# The list of branches to process.
branches = ["master"]

# The region we operate in, dictated by terraform.
theRegion = "us-east-2"
# The availibility zone, which we use just one zone.
zone = theRegion + 'a'

# For when we need to wait for something to get done while in a loop, wait this long.
wait = 1

# Script used to do all the ssh stuff with the remote host and run the test.
test_script = "/home/admin/fog-community-scripts/fog-aws-testing/scripts/test_instance.sh"

webdir = '/tmp/webdir'
statusDir = '/tmp'

indexHtml = '/home/admin/fog-community-scripts/fog-aws-testing/scripts/index.html'

green = "green.png"
orange = "orange.png"
red = "red.png"

domainname = "fogtesting.theworkmans.us"
http = "http://"
port = ""
netdir = ""

remoteResult = "/root/result"


ssh = "/usr/bin/ssh"
scp = "/usr/bin/scp"
timeout = "/usr/bin/timeout"

sshTimeout = 15
fogTimeout= "20m" #Time to wait for FOG installation to complete. Must end with a unit of time. s for seconds, m for minutes.
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






