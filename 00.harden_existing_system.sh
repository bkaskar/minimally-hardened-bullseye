#!/usr/bin/env bash

BASEDIR=$(pwd)

source 01.download_pwqual_dict.sh
source 02.strengthen_pam.sh
cd $BASEDIR
source 03.module_disable.sh
source 04.update_kern_params.sh
source 05.cron_ownerships.sh
source 06.update_sshd.sh
source 07.firewall_and_audit.sh

cd 08.falcon-agent
./install.sh

