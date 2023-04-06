#!/usr/bin/env bash
#########################################################################
#                     ~- Debian 11 baseline hardening -~                #
# Assumption is that 01.download_pwqual_dict.sh copied H0bo dictionary  #
# under /usr/share/dict, other PAM related tweaks can be run separately # 
# But having it done all at once keeps password related items together. # 
# Thus if dict check fails, the whole thing fails.                      #
# Part of D116 baseline hardening guide by bkaskar                      #
# Author: bkaskar                                                       #
#########################################################################

D=" Done!"

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit 
fi

if [ -f "/usr/share/dict/rockyou.txt.gz" ]
  then echo -n "Adding Password Quality updates..."

  apt -y install -qq libpam-pwquality && \
  apt -y install -qq libpwquality-tools && \
  cd /usr/share/dict && \
  gunzip -d /usr/share/dict/rockyou.txt.gz && \
  update-cracklib
  echo $D


  PWF="/etc/pam.d/common-password"
  cp ${PWF} ${PWF}.orig
  if [ $(grep -c pam_pwquality ${PWF} ) -ne 1 ]
    then echo -n "Updating ${PWF} ... "
    sed -ie "s/try_first_pass yescrypt$/try_first_pass yescrypt remember=20/" ${PWF}
    if [[ "$?" != 0 ]] 
      then echo "Please update ${PWF} manually by adding remember=20, after yesscrypt"
    else
      echo $D
    fi
  fi


  PWF="/etc/pam.d/common-session"
  cp ${PWF} ${PWF}.orig
  if [ $(grep -c pam_umask ${PWF} ) -ne 1 ]
    then echo -n "Updating ${PWF} ... "
    sed -i -e "/pam_unix.so/ a\
session optional        pam_umask.so\
    " ${PWF}
    if [[ "$?" != 0 ]]
      then echo "Please update ${PWF} by adding \"session optional        pam_umask.so\""
           echo "as new line after \"session required\" config definitions"
    else
      echo $D
    fi
  fi


  PWF="/etc/security/pwquality.conf"
  cp ${PWF} ${PWF}.orig
  if [ -f ${PWF} ]
    then echo -n "Updating ${PWF}... "
    sed -i -e "s/^[#]*[[:space:]]*\(difok\).*/\1 = 4/g" -e "s/^[#]*[[:space:]]*\(minlen\).*/\1 = 14/g" \
           -e "s/^[#]*[[:space:]]*\(dcredit\).*/\1 = -1/g" -e "s/^[#]*[[:space:]]*\(ucredit\).*/\1 = -1/g" \
           -e "s/^[#]*[[:space:]]*\(lcredit\).*/\1 = -1/g" -e "s/^[#]*[[:space:]]*\(ocredit\).*/\1 = -1/g" \
           -e "s/^[#]*[[:space:]]*\(ocredit\).*/\1 = -1/g" -e "s/^[#]*[[:space:]]*\(minclass\).*/\1 = 4/g" \
           -e "s/^[#]*[[:space:]]*\(maxrepeat\).*/\1 = 3g/" -e "s/^[#]*[[:space:]]*\(dictcheck\).*/\1 = 1/g" \
           -e "s/^[#]*[[:space:]]*\(retry\).*/\1 = 3/g" -e "s/^[#]*[[:space:]]*\(enforce_for_root\).*/\1/g" ${PWF}
    echo $D
  fi

  PWF="/etc/login.defs"
  cp ${PWF} ${PWF}.orig
  if [ -f ${PWF} ]
    then echo -n "Updating ${PWF}... "
    sed -i -e "s/^\(PASS_MAX_DAY\).*/\1     90/g" \
           -e "s/^\(PASS_MIN_DAY\).*/\1     7/g" \
           -e "s/^\(PASS_WARN_AGE\).*/\1    14/g" \
           -e "s/^\(UMASK\).*/\1	022/g" \
           -e "s/^#USERDEL_CMD/USERDEL_CMD/" ${PWF}
    echo $D
  fi
  echo "Please run the command pam-auth-update hit OK to finalize the process"
else 
  echo "Latest dictionary not found, please run download_pwqual_dict.sh before starting this process"
  exit
fi

