#!/bin/bash

apt-get update
apt-get -y dist-upgrade

apt-get -y install git
git clone https://github.com/wayneworkman/fog-community-scripts.git
cd fog-community-scripts/fog_analytics/analytics

# install server software.
bash setup.sh

# Schedule a reboot in 10 seconds after this script as exited.
(sleep 10 && sudo reboot)&

