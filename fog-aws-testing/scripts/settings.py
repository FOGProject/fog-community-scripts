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

