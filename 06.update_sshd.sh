#!/usr/bin/env bash
############################################################################
#                   ~- Debian 11 baseline hardening -~                     #
# Update SSHD configuration and add strong MAC and Ciphers as part of D116 #
# baseline hardening guide by bkaskar                                      #
# Why this was created, there are plenty available in guthub.com?          #
# Requirement is to listen to just one IP (internal preferably).           #
# Also, other examples copy over existing sshd_config, whereas this script #
# takes care of only configuration line items and does not mess with other #
# lines such as comments in the SSHD_CONFIG file so if other configs are   #
# brought over they will remain, but the settings you want to restrict will#
# be controlled through this even if anything is added additionally.       #
#                                                                          #
# Author: bkaskar                                                          #
# Config: /etc/ssh/sshd_config                                             #
############################################################################

D=" Done!"

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit 
fi

#Backup orignal file
PWF="/etc/ssh/sshd_config"
cp ${PWF} ${PWF}.orig 

HOST_PRIMARY_IP="0.0.0.0"

if [ $(ip -o -4 link | grep -cv loopback) -ne 0 ]
  then ADAPTERS=()
  for ADAPTER in "$(ip -o -4 link | grep -v loopback | awk '{print $2}')"
    do ADAPTER=$(echo ${ADAPTER} | cut -d: -f1)
    ADAPTERS+=("${ADAPTER}")
  done
  
  # single homed system will have the default IP as Listening for SSHD 
  if [ ${#ADAPTERS[@]} -eq 1 ]
    then HOST_PRIMARY_IP=$(ip -4 address | grep inet | grep ${ADAPTERS[@]} | awk '{print $2}' | cut -d/ -f1)
  fi

  # If the system is multihomed please update the script to prompt and select
  if [ ${#ADAPTERS[@]} -gt 1 ]
     then IFS=@
     echo "Select a nic for SSHD to listen on (enter a number for adapter 1,2...)"
     select AD in "${ADAPTERS[@]}" "None"
       do case "${AD}" in
            (*"@$1@"*) echo "selected one is ${AD}"
                 break
                 ;;
         esac
         HOST_PRIMARY_IP=$(ip -4 address | grep inet | grep ${AD} | awk '{print $2}' | cut -d/ -f1)
         break
     done
  fi 
fi

if [[ $HOST_PRIMARY_IP == "0.0.0.0" ]] 
  then echo "Host Adapter not set, cannot proceed... bailing out!!"
  exit 
fi

# Make sure only the select IP is ised as Listen Address
if [ -f ${PWF} ]
  then echo -n "Updating ${HOST_PRIMARY_IP}:port in ${PWF}... "
  sed -i -e "s/^[#]*[[:space:]]*\(Port\).*\([0-9]\{1,\}\)/\1 22/g" \
         -e "s/^#ListenAddress 0.0.0.0/ListenAddress ${HOST_PRIMARY_IP}/" ${PWF}
  echo "${D}"
fi

# Make sure client takes care of livelihood
if [ -f ${PWF} ]
  then echo -n "Updating KeepAlive settings... "
  sed -i -e "s/^[#]*[[:space:]]*\(ClientAliveInterval\).*\([0-9]\{1,\}\)/\1 35/g" \
         -e "s/^[#]*[[:space:]]*\(TCPKeepAlive\).*\(yes\|no\)/\1 no/g" ${PWF}
  echo "${D}"
fi

# Allow client to pass locale environment variables
echo -n "Allow client to pass locale..."
if [ $(grep -c -e "AcceptEnv LANG" ${PWF}) -eq 1 ]
  then sed -i -e "s/^[#]*[[:space:]]*\(AcceptEnv LANG LC_\).*/\1*/g" ${PWF}
else
  sed -i -e "/ClientAliveInterval/ a\
\AcceptEnv LANG LC_*\
" ${PWF}
fi
echo "${D}"

# Disable User/Group 
echo -n "Disable User/Groups"
if [ $(grep -c -e "^[#]*[[:space:]]*AllowUsers" ${PWF}) -eq 1 ]
  then sed -i -e "s/^[#]*[[:space:]]*\(AllowUsers\).*/#\1 user/g" ${PWF}
fi

if [ $(grep -c -e "^[#]*[[:space:]]*AllowGroups" ${PWF}) -eq 1 ]
  then sed -i -e "s/^[#]*[[:space:]]*\(AllowGroups\).*/#\1 group/g" ${PWF}
fi
echo "${D}"

echo -n "Applying Elliptic Curve Diffie-Hellman over Curve25519 with SHA2"
if [ $(grep -c -e "^[#]*[[:space:]]*KexAlgorithms" ${PWF}) -eq 0 ] 
  then cat >>${PWF}<< EOF

#
# IBM CISO-SIR Recommended Key Exchange Algorithms
# 
# Supported Key Exchange Algorithms
## Elliptic Curve Diffie-Hellman over Curve25519 with SHA2
## Custom DH with SHA2 (not being specific to 14/16/18 groups
KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256

EOF
else 
  sed -i -e "s/^[#]*[[:space:]]*\(KexAlgorithms\).*$/\1 curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256/g" ${PWF}
fi
echo "${D}"

echo -n "Applying Supported Message Authentication Codes..."
if [ $(grep -c -e "^[#]*[[:space:]]*MACs" ${PWF}) -eq 0 ]
  then cat >>${PWF}<< EOF

#
# IBM CISO-SIR Recommended Message Authentication Codes
#
# Supported Message Authentication Codes (integrity algorithm)
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,umac-128@openssh.com
EOF
else
  sed -i -e "s/^[#]*[[:space:]]*\(MACs\).*$/\1 hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,umac-128@openssh.com/g" ${PWF}
fi
echo "${D}"

echo -n "Applying Supported Ciphers used to Encrypt payload..."
if [ $(grep -c -e "^[#]*[[:space:]]*Ciphers" ${PWF}) -eq 0 ]
  then cat >>${PWF}<< EOF

#
# IBM CISO-SIR Recommended Cipher suite
#
# Supported Ciphers used to Encrypt the data (payload)
Ciphers aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
EOF
else
  sed -i -e "s/^[#]*[[:space:]]*\(Ciphers\).*$/\1 aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr/g" ${PWF}
fi
echo "${D}"

# While at it Update Accepted publickey types as well
echo -n "Reject sk- or other weak public keys..."
if [ $(grep -c -e "^[#]*[[:space:]]*PubkeyAcceptedKeyTypes" ${PWF}) -eq 0 ]
  then cat >>${PWF}<< EOF

#
# IBM CISO-SIR Recommended Public Keys to accept
#
# Supported Public Keys are only non sk- type ones and also FIPS supported
PubkeyAcceptedKeyTypes ecdsa-sha2-nistp256-cert-v01@openssh.com,ecdsa-sha2-nistp384-cert-v01@openssh.com,ecdsa-sha2-nistp521-cert-v01@openssh.com,ssh-ed25519-cert-v01@openssh.com,ecdsa-sha2-nistp256,ecdsa-sha2-nistp384,ecdsa-sha2-nistp521,ssh-ed25519
EOF
else
  sed -i -e "s/^[#]*[[:space:]]*\(PubkeyAcceptedKeyTypes\).*$/\1 ecdsa-sha2-nistp256-cert-v01@openssh.com,ecdsa-sha2-nistp384-cert-v01@openssh.com,ecdsa-sha2-nistp521-cert-v01@openssh.com,ssh-ed25519-cert-v01@openssh.com,ecdsa-sha2-nistp256,ecdsa-sha2-nistp384,ecdsa-sha2-nistp521,ssh-ed25519/g" ${PWF}
fi
echo "${D}"


# Logging
if [ -f ${PWF} ]
  then echo -n "Logging update in ${PWF}... "
  sed -i -e "s/^[#]*[[:space:]]*\(LogLevel\).*$/\1 VERBOSE/g" \
         -e "s/^[#]*[[:space:]]*\(PrintLastLog\).*\(yes\|no\)/\1 yes/g" \
         -e "s/^[#]*[[:space:]]*\(SyslogFacility\).*$/\1 AUTHPRIV/g" ${PWF}
  echo "${D}"
fi

# Fix deprecated stuff and Enforce Protocol 2
if [ $(grep -c -e "^[#]*[[:space:]]*UseLogin.*\(yes\|no\)" ${PWF}) -eq 1 ]
  then sed -i -e "s/^[#]*[[:space:]]*\(UseLogin\).*\(yes\|no\)//g" ${PWF}
fi

if [ $(grep -c -e "^[#]*[[:space:]]*RSAAuthentication.*\(yes\|no\)" ${PWF}) -eq 1 ]
  then sed -i -e "s/^[#]*[[:space:]]*\(RSAAuthentication\).*\(yes\|no\)//g" ${PWF}
fi

if [ $(grep -c -e "^[#]*[[:space:]]*RhostsRSAAuthentication.*\(yes\|no\)" ${PWF}) -eq 1 ]
  then sed -i -e "s/^[#]*[[:space:]]*\(RhostsRSAAuthentication\).*\(yes\|no\)//g" ${PWF}
fi

if [ $(grep -c -e "^[#]*[[:space:]]*UsePrivilegeSeparation.*\(yes\|no\)" ${PWF}) -eq 1 ]
  then sed -i -e "s/^[#]*[[:space:]]*\(UsePrivilegeSeparation\).*\(yes\|no\)//g" ${PWF}
fi

# Force Protocol 2
echo -n "Forcing Protocol 2"
if [ $(grep -c -e "^[#]*[[:space:]]*Protocol" ${PWF}) -eq 1 ]
  then sed -i -e "s/^[#]*[[:space:]]*\(Protocol\).*$/\1 2/g" ${PWF}
fi
echo "${D}"

# Login
if [ -f ${PWF} ]
  then echo -n "Login update in ${PWF}... "
  sed -i -e "s/^[#]*[[:space:]]*\(MaxSessions\).*\([0-9]\{1,\}\)/\1 3/g" \
         -e "s/^[#]*[[:space:]]*\(MaxAuthTries\).*\([0-9]\{1,\}\)/\1 3/g" \
         -e "s/^[#]*[[:space:]]*\(LoginGraceTime\).*\([0-9]\{1,\}\)/\1 45/g" \
         -e "s/^[#]*[[:space:]]*\(PermitRootLogin\).*\(yes\|no\)/\1 no/g" \
         -e "s/^[#]*[[:space:]]*\(PermitUserRC\).*\(yes\|no\)/\1 no/g" \
         -e "s/^[#]*[[:space:]]*\(AllowTcpForwarding\).*\(yes\|no\)/\1 no/g" \
         -e "s/^[#]*[[:space:]]*\(AllowAgentForwarding\).*\(yes\|no\)/\1 no/g" \
         -e "s/^[#]*[[:space:]]*\(PermitEmptyPasswords\).*\(yes\|no\)/\1 no/g" \
         -e "s/^[#]*[[:space:]]*\(HostbasedAuthentication\).*\(yes\|no\)/\1 no/g" \
         -e "s/^[#]*[[:space:]]*\(ChallengeResponseAuthentication\).*\(yes\|no\)/\1 no/g" \
         -e "s/^[#]*[[:space:]]*\(PasswordAuthentication\).*\(yes\|no\)/\1 yes/g" \
         -e "s/^[#]*[[:space:]]*\(IgnoreUserKnownHosts\).*\(yes\|no\)/\1 yes/g" \
         -e "s/^[#]*[[:space:]]*\(PubkeyAuthentication\).*\(yes\|no\)/\1 yes/g" \
         -e "s/^[#]*[[:space:]]*\(StrictModes\).*\(yes\|no\)/\1 yes/g" ${PWF}
  echo "${D}"
fi


# Update Banner 
if [ -f ./issue ]
  then cp -f issue /etc/
fi

if [ -f ./issue.net ]
  then cp -f issue.net /etc/
fi

# User Banner instead of motd
  if [ -f ${PWF} ]
    then echo -n "Banner update in ${PWF}... "
    sed -i -e "s/^[#]*[[:space:]]*\(Banner\).*/\1 \/etc\/issue.net/g" \
           -e "s/^[#]*[[:space:]]*\(PrintMotd\).*\(yes\|no\)/\1 no/g" ${PWF}
    echo "${D}"
  fi


if [ $(grep -c -e "AllowStreamLocalForwarding" ${PWF}) -eq 0 ] 
  then cat >>${PWF}<< EOF

# Permit Unix-domain socket forwarding
# Does not improve security unless users are also denied shell access
AllowStreamLocalForwarding no
EOF
fi

# SFTP update mandate to default subsystem
if [ $(grep -c -e "ForceCommand[[:space:]]*internal-sftp" ${PWF}) -eq 1 ]
  then echo -n "Updating SFTP ..."
  sed -i -e "s/^[#]*[[:space:]]*\(ForceCommand\).*internal-sftp/#\1 internal-sftp/g" ${PWF}
else
  sed -i -e "/sftp-server/ a\
\#ForceCommand        internal-sftp\
" ${PWF}
fi
sed -i -e "s/^[#]*[[:space:]]*\(Subsystem.*sftp-server\)\(.*$\)/\1 -f AUTHPRIV -l INFO/g" ${PWF}
echo "${D}"

# Last of the settings
if [ -f ${PWF} ]
  then echo -n "Updating performance, forwarding, other connectivity settings... "
  sed -i -e "s/^[#]*[[:space:]]*\(IPQoS\)\(.*\)/#\1 \2/g" \
         -e "s/^[#]*[[:space:]]*\(UseDNS\).*\(yes\|no\)/#\1 no/g" \
         -e "s/^[#]*[[:space:]]*\(GatewayPorts\).*\(yes\|no\)/\1 no/g" \
         -e "s/^[#]*[[:space:]]*\(PermitTunnel\).*\(yes\|no\)/\1 no/g" \
         -e "s/^[#]*[[:space:]]*\(X11Forwarding\).*\(yes\|no\)/\1 no/g" \
         -e "s/^[#]*[[:space:]]*\(Compression\).*\(yes\|no\)/\1 yes/g" \
         -e "s/^[#]*[[:space:]]*\(PermitTTY\).*\(yes\|no\)/\1 yes/g" ${PWF}
  echo "${D}"
fi

# Host Keys used for Server Authentication (signing algorithms)
if [ -f ${PWF} ]
  then echo -n "Updating HostKeys used in ${PWF}... "
  echo -n "Regenerating host keys, please make sure to update your local known_hosts before re-connecting"
  rm -f /etc/ssh/ssh_host_*_{key,key.pub}
  ssh-keygen -A
  ## Edwards-curve Digital Signature Algorithm (EdDSA) using Curve25519 with SHA512
  sed -i -e "s/^[#]*[[:space:]]*\(Host.*ssh_host_ed25519_key\).*/\1/g" \
         -e "s/^[#]*[[:space:]]*\(Host.*ssh_host_rsa_key\).*/\1/g" \
         -e "s/^[#]*[[:space:]]*\(Host.*ssh_host_ecdsa_key\).*/#\1/g" ${PWF}
  echo "${D}"
fi

/usr/sbin/sshd -t -f ${PWF} 
if [[ "$?" != 0 ]] 
  then echo "All updates ran successfully"
  echo "Update your local signature by running \"ssh-keygen -R ${HOSTNAME}\" for this server"
  echo "or manually update your HOME/.ssh/known_hosts before re-connecting with PuTTY you may need to use strong cipher"
  rm -f ${PWF}.orig
else
  echo "Please check the messages above carefully, as a hardening update (or more) may have failed."
  mv ${PWF}.orig ${PWF}
fi
systemctl restart sshd.service
