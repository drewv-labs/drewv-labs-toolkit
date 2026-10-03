#!/bin/zsh
# Deploy the lildebbyhelpers to targeted VF2-Hailo8 Engine node.
scp ./lildebbyhelpers/*.sh "${1}:"
