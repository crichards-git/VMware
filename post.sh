#!/bin/bash
# VMware Post Install Script for CentOS and Ubuntu
# v1.6

GREEN="\e[32m"
RED="\e[31m"
ENDCOLOR="\e[0m"

# Set Hostname

echo -en "${GREEN}HOSTNAME:${ENDCOLOR}"
read hostname
echo $hostname > /etc/hostname

# Set UID

echo -en "${GREEN}UID:${ENDCOLOR}"
read uid
echo $uid > /usr/local/lp/etc/lp-UID

# Resize Drive and FS

echo -e "${GREEN}Resizing LVM and Filesystem${ENDCOLOR}"

echo 1 > /sys/class/block/sda/device/rescan
if [ -f /etc/centos-release ] || [ -f /etc/redhat-release ]; then
    parted /dev/sda resizepart 2 -- -1
    pvresize /dev/sda2
    lvresize -r -l +95%FREE /dev/mapper/centos-root
elif [ -f /etc/lsb-release ]; then
    parted /dev/sda resizepart 3 -- -1
    pvresize /dev/sda3
    lvresize -r -l +95%FREE /dev/mapper/ubuntu--vg-ubuntu--lv
else
    echo -e "${RED}ERROR! Check LVM and Filesystem${ENDCOLOR}"
    exit 1
fi

echo -e "${GREEN}Done${ENDCOLOR}"

# Package Updates

echo -e "${GREEN}Packages Updating${ENDCOLOR}"

if [ -f /etc/centos-release ] || [ -f /etc/redhat-release ]; then
    yum update -y ; yum install -y kernel-devel ; yum install -y open-vm-tools
elif [ -f /etc/lsb-release ]; then
    apt update ; apt upgrade -y ; apt install -y open-vm-tools
else
    echo -e "${RED}ERROR! Make Sure Distro is RPM or APT Based${ENDCOLOR}"
    exit 1
fi

echo -e "${GREEN}Done${ENDCOLOR}"

# Cpanel License Refresh (if applicable)

if [ -f /usr/local/cpanel/cpkeyclt ]; then
echo -e "${GREEN}Did You Get a Cpanel License?${ENDCOLOR}"
select cp in "Yes" "No"; do
    case $cp in
        Yes ) /usr/local/cpanel/cpkeyclt; /usr/local/cpanel/scripts/build_cpnat; break;;
        No ) echo -e "${GREEN}Get a License and Select 1${ENDCOLOR}";;
    esac
done
fi

# Acronis (if applicable)

echo -e "${GREEN}Download Acronis?${ENDCOLOR}"
select ac in "Yes" "No"; do
    case $ac in
        Yes ) wget 'https://us5-cloud.acronis.com/bc/api/ams/links/agents/redirect?language=multi&system=linux&architecture=64&productType=enterprise' -O acronis.bin ; break;;
        No ) break;;
    esac
done

# System Summary

echo -e "${GREEN}HOSTNAME${ENDCOLOR}: $hostname"
echo -e "${GREEN}UID${ENDCOLOR}: $uid"
echo -e "${GREEN}Drive Layout${ENDCOLOR}"
lsblk
echo -e "${GREEN}Memory${ENDCOLOR}"
free -h

# Confirm and Remove Script

echo -e "${GREEN}Does Everything Look Correct?${ENDCOLOR}"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) rm VMware/post.sh ; exit;;
        No ) exit;;
    esac
done
