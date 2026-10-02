#!/bin/bash
# Fix missing locales on VF2 Hailo-8 Engine installs
# Run with: sudo ./setup_locale.sh
sudo apt update -y
sudo apt install -y locales
sudo sed -i 's/^# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sudo locale-gen
sudo update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
