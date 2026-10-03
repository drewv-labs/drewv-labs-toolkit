#!/bin/zsh
# usage: ./debbyhelpers/drop-default-user.sh
# Prints the commands to run on target Debian VF2 board
# to safely drop the default pre-configured user account.
# This should be done after adding the main user account
# (add-new-sudo-user.sh) to eliminate security vulernabilities.
echo "sudo pkill -u user"
echo "sudo deluser --remove-home user"
echo "sudo rm -f /etc/sudoers.d/user"
