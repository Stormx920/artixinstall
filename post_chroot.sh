#!/bin/bash
LIGHTRED='\033[1;91m'
LIGHTGREEN='\033[1;32m'
source /etc/profile
cd /

printf ${CYAN}"Enter the username for your NON ROOT user\n>"
#There is a possibility this won't work since the handbook creates a user after rebooting and logging as root
read username
useradd -mG wheel,audio,video,groups $username
printf ${CYAN}"Enter the Hostname you want to use\n>"
read hostname
echo $hostname >> /etc/hostname
printf "Enter your timezone\ne.g. Europe/Berlin\n>"
read timezone
ln -sf /usr/share/zoneinfo/$timezone /etc/localtime
hwclock --systohc
printf "Installing bootloader"
sudo pacman -S grub os-prober
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Artix
grub-mkconfig -o /boot/grub/grub.cfg

printf "Now you only need to edit your locale.gen, locale.conf and run locale-gen!"
exit 0
