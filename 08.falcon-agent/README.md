As of writing (Mar 2023) the current version for FalconSensor is falcon-sensor_6.50.0-14713_amd64.

## Where to get the latest FalconSensor deb package? 
  You can get it from https://github.ibm.com/cisoedr/crowdstrike-sensor/tree/master/WW/Linux/N  
  Just in-case if the server needs to be deployed in a secluded/island network only reporting to EDR 
for suspected intrusion. First download the latest package from there, update in the install.sh before registering the host to EDR.

## A(gent)ID check. 
CrowdStrike Registration takes a while, and may initially run in RFM Mode (rfm = true). If the install.sh aid check fails at the end of 1 min, this a known issue with the package. Please wait at least for 5 minutes and check again before raising an issue. You receive an aid, but during init it runs in r(educed)f(unctionality)m(mode).
