#!/bin/zsh
# Deploy the carepackage to targeted VF2-Hailo8 Engine node.
scp ./carepackage/*.sh "${1}:"
