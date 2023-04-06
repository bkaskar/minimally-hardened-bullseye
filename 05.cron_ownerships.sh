#!/bin/bash
#########################################################################
#                     ~- Debian 11 baseline hardening -~                #
# Download Hob0 rules separately first and copy over to /usr/share/dict #
# Part of D116 baseline hardening guide by Bhaskar Roy, Rick Torres Jr. #
# Author: broy@ibm.com                                                  #
#########################################################################
cronfiles=(
crontab
cron.hourly
cron.daily
cron.weekly
cron.monthly
cron.d
)
for x in "${cronfiles[@]}"; do
    chmod og-rwx /etc/${x} && chown root:root /etc/${x}
done
