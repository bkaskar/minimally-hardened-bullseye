#!/bin/bash
#########################################################################
#                     ~- Debian 11 baseline hardening -~                #
# Download Hob0 rules separately first and copy over to /usr/share/dict #
# Part of D116 baseline hardening guide by Bhaskar Roy, Rick Torres Jr. #
# Author: broy@ibm.com                                                  #
#########################################################################

if [ "$EUID" -ne 0 ]
  then echo "Please run as root and from baseline dir"
  exit 
fi

echo "Updating base system first"
apt update -y && apt dist-upgrade -y && apt upgrade -y

echo -n "Downloading pwquality update ..."
wget -O ./rockyou.txt.gz -v https://github.com/praetorian-inc/Hob0Rules/raw/master/wordlists/rockyou.txt.gz &> /dev/null

if [[ "$?" != 0 ]]
  then echo " Error downloading file please try manually"
  echo "Please visit https://github.com/praetorian-inc/Hob0Rules for more info"
  exit
else
    echo ". Success!!"
fi

echo "Do you wish to copy pwquality dict for inclusion? (enter 1 or 2)"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) mv ./rockyou.txt.gz /usr/share/dict/; break;;
        No ) exit;;
    esac
done

