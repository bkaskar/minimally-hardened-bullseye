#!/bin/bash
#########################################################################
#                     ~- Debian 11 baseline hardening -~                #
# This is just some of the basic modules and may need further fine tune #
# You may even have to remove some of these if the systems is being bu- #
# ilt for some specific purpose were you would need say udf or psnap    #
# Part of D116 baseline hardening guide by Bhaskar Roy, Rick Torres Jr. #
# Author: broy@ibm.com                                                  #
#                                                                       #
# Note: llc fakeinstall is disbled because docker install failed with:  #   
# msg="Running modprobe bridge br_netfilter failed with message:
# modprobe: ERROR: could not insert 'bridge': Unknown symbol in module,
# or unknown parameter (see dmesg)
# modprobe: ERROR: could not insert 'br_netfilter': Unknown symbol in
# module, or unknown parameter (see dmesg)
#
# install /bin/true
# insmod /lib/modules/5.10.0-21-amd64/kernel/net/802/stp.ko ,
# error: exit status 1"
# This meant for 'br_netfilter' to load "bridge" is needed and for that #
# both "llc" and "stp" modules are needed. However, the deny list below #
# does not contain stp. So, by running then it must be the llc module.  #
# But, how do you know? which module depends on which? Just by running  #
# "modinfo bridge" you could see it's dependent on both stp and llc     #
# (which was one of the modules being disabled here, thus re-enabled).  #
#########################################################################

DISABLE_MODULES=(
# disabled_fs_modules
cramfs
freevxfs
hfs
hfsplus
jffs2
squashfs
udf
# disabled_misc_modules
bluetooth
bnep
btusb
can
cpia2
firewire-core
floppy
ksmbd
pcspkr
soundcore
thunderbolt
usb-midi
usb-storage
uvcvideo
v4l2_common
# disabled_net_modules
af_802154
appletalk
atm
ax25
dccp
decent
econet
ipx
#llc
n-hdlc
net-pf-31
netrom
p8022
p8023
psnap
rds
rose
sctp
tipc
x25
)
for x in "${DISABLE_MODULES[@]}"; do
    echo "install $x /bin/true" > /etc/modprobe.d/${x}.conf && \
    echo "blacklist $x" >> /etc/modprobe.d/${x}.conf
done
