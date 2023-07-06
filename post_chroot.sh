#!/bin/bash
LIGHTRED='\033[1;91m'
LIGHTGREEN='\033[1;32m'
source /etc/profile
scriptdir=$(pwd)
cd ..

printf ${CYAN}"Enter the username for your NON ROOT user\n>"
#There is a possibility this won't work since the handbook creates a user after rebooting and logging as root
read username
username="${username,,}"
useradd -mG wheel,audio,video,groups $username
printf ${CYAN}"Enter the Hostname you want to use\n>"
read hostname
echo $hostname >> /etc/hostname
