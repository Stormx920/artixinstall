#!/bin/bash

LIGHTGREEN='\033[1;32m'
LIGHTRED='\033[1;91m'
WHITE='\033[1;97m'
MAGENTA='\033[1;35m'
CYAN='\033[1;96m'
cd ..
start_dir=$(pwd)
fdisk -l >> devices
sed -e '\#Disk /dev/ram#,+5d' -i devices
sed -e '\#Disk /dev/loop#,+5d' -i devices

cat devices

while true; do
    printf ${CYAN}"Enter the device name you want to install artix on (ex, sda for /dev/sda)\n>"
    read disk
    disk="${disk,,}"
    partition_count="$(grep -o $disk devices | wc -l)"
    disk_chk=("/dev/${disk}")
    if grep "$disk_chk" devices; then
        printf "Would you like to auto provision %s? \n This will create a GPT partition scheme where\n%s1 = 2 MB bios_partition\n%s2 = 128 MB boot partition\n%s3 = 4 GB swap_partition\n%s4 x GB root partition (the rest of the hard disk)\n\nEnter y to continue with auto provision or n to exit the script \n>" $disk_chk $disk_chk $disk_chk $disk_chk $disk_chk
        read auto_prov_ans
        if [ "$auto_prov_ans" = "y" ]; then
            wipefs -a $disk_chk
            parted -a optimal $disk_chk --script mklabel gpt
            parted $disk_chk --script mkpart primary 1MiB 257MiB
            parted $disk_chk --script name 1 grub
            parted $disk_chk --script set 1 bios_grub on
            parted $disk_chk --script mkpart primary 257MiB 4353MiB
            parted $disk_chk --script name 2 swap
            parted $disk_chk --script -- mkpart primary 4353MiB -1
            parted $disk_chk --script name 3 artix
            parted $disk_chk --script set 1 boot on
            part_1=("${disk_chk}1")
            part_2=("${disk_chk}2")
            part_3=("${disk_chk}3")
            mkfs.fat -F 32 $part_1
            #mkfs.ext4 $part_2
            mkfs.ext4 $part_3
            mkswap $part_2
            swapon $part_2
            rm -rf devices
            clear
            sleep 2
            break
        elif [ "$auto_prov_ans" = "n" ]; then
            printf ${CYAN}"Enter the partition number for root (ex, 2 for /dev/sda2)\n>"
            read num
            rootpart="$disk$num"
            if grep "$rootpart" devices; then
                #continue running the script
                if [ $partition_count -gt 2 ]; then
                    printf "do you want to enable swap?\n>"
                    read swap_answer
                fi
                swap_answer="${swap_answer,,}"
                if [ "$swap_answer" = "no" ]; then
                    printf "not using swap"
                    part_3="no"
                else
                    while true; do
                        printf "enter swap partition (ex, /dev/sda3)\n>"
                        read part_3
                        part_3="${part_3,,}"
                        if grep "$part_3" devices; then
                            mkswap $part_3
                            swapon $part_3
                            break
                        else
                            printf${LIGHTRED}"%s is not a valid swap partition, review this list of your devices and make a valid selection\n" $part_3
                            printf ${WHITE}".\n"
                            sleep 5
                            clear
                            cat devices
                        fi
                    done
                fi
                printf ${LIGHTGREEN}"%s is valid :D continuing with the script\n" $rootpart
                break
            else
                #rootpartnotfound
                printf ${LIGHTRED}"%s is not a valid installation target, review this list of your devices and make a valid selection\n" $rootpart
                printf ${WHITE}".\n"
                sleep 5
                clear
            fi
        else
            printf ${LIGHTRED}"%s is an invalid answer, do it correctly" $auto_prov_ans
            printf ${WHITE}".\n"
            sleep 2
        fi
    else
        printf ${LIGHTRED}"%s is an invalid device, try again with a correct one\n" $disk_chk
        printf ${WHITE}".\n"
        sleep 5
        clear
        cat devices
    fi
done

artix-chroot /mnt ./post_chroot.sh
