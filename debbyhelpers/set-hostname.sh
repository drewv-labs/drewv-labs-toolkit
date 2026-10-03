#!/bin/zsh
# usage: ./debbyhelpers/set-hostname.sh <hostname>
# Prints the commands to set the hostname and update /etc/hosts
echo "sudo hostnamectl set-hostname ${1}"
echo "sudo sed -i 's/starfive/${1}/g' /etc/hosts"
