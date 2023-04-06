#!/bin/bash
#########################################################################
#                     ~- Debian 11 baseline hardening -~                #
# This script installs firewall and lynis to audit the system as part   #
# of D116 baseline hardening guide by Bhaskar Roy, Rick Torres Jr.      #
# Author: broy@ibm.com                                                  #
#########################################################################

if [ "$EUID" -ne 0 ]
  then echo "Please run as root and from baseline dir"
  exit 
fi

echo "Removing certain packages to further reduce threat surface"
apt -y remove -qq bluetooth busybox wpasupplicant xxd
apt -y autoremove

echo "Installing audit scanning tools"
apt -y install -qq ufw lynis debsecan

echo "Enabling local firewall"
ufw default allow outgoing && \
ufw default deny incoming && \
ufw allow ssh && \
ufw status 

ufw enable

echo "After installing Falcon Agent, please \"restart\" the system and run \"lynis audit system\""
