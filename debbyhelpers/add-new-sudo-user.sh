#!/bin/zsh
# usage: ./debbyhelpers/add-new-sudo-users.sh[ <user>]
# Prints out the commands to add user
local_usr="$(whoami)"
usr="${1:-$local_usr}"

echo "su -"
echo "adduser $usr"
echo "usermod -aG sudo,adm,dialout $usr"
