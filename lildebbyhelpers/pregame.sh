#!/bin/bash
# usage: ./debbyhelpers/pregame.sh <user> <hostname>
# Prints out the commands to add user

# // Add the main user
usr="${1}"
sudo adduser "$usr"
sudo usermod -aG sudo,adm,dialout "$usr"

# // Remove the default user
sudo pkill -u user
sudo deluser --remove-home user
sudo rm -f /etc/sudoers.d/user

# // Update default hostname
hname="${2:-starfive}"
sudo hostnamectl set-hostname "$hname"
sudo sed -i "s/starfive/${hname}/g" /etc/hosts
