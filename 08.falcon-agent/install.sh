#!/bin/bash

INSTALLBIN="ww-falcon-sensor-amd64.deb";

cid="UNKNOWN"
tags="ADDME"

if [ -f .falcon-agent ] 
  then source .falcon-agent
  cid=${CID}
  tags=${TAGS}
else 
  echo "Please add customer id and tags for your install before proceeding"
  exit 
fi

if [ ! -f ${INSTALLBIN} ]
  then echo "Please download the latest package per README before proceeding"
  exit 
fi

# for remote pull
#curl -o "$localSensorPath" "$INSTALLBIN"

### INSTALL SENSOR ###

# IF DEBIAN
# If you run into a dependency issue, try this
apt --fix-broken -y install -qq ./ww-falcon-sensor-amd64.deb

### CONFIGURE SENSOR ###
echo -n "Configuring EDR agent for startup ... "
/opt/CrowdStrike/falconctl -s --cid=$cid && \
/opt/CrowdStrike/falconctl -s --tags=$tags && \
service falcon-sensor start && \
systemctl enable falcon-sensor
echo " Done!"

### CHECK RFM-MODE ###
echo " "
echo "Checking if initial service registration was successful. Next, you should"
echo "see an a(gent)id [aid] reporting \"rfm-state=false\" for proper monitoring." 
echo "Sometimes registration process takes time and you only can wait till the"
echo "next valid polling. In case the agent fails to run due to incompatibility."
echo "You may need to update the system to the latest suppported kernel version"
echo "acceptable to the sensor package, and then, run the script again."
echo "If everything went well, you will NOT see \"rfm-state=true\" next."

echo -n "Waiting 1 min for initial service registration "
for i in 0 1 2 3 4 5
do echo -n "."
sleep 10 
done
echo " Done!"
/opt/CrowdStrike/falconctl -g --rfm-state --version --aid


