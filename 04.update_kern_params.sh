#!/bin/bash
############################################################################
#                   ~- Debian 11 baseline hardening -~                     #
# Update Kernel parameters only to satisfy lynis audits. For CIS Benchmark #
# You may need additional tweaking. Also it depends on what your system is #
# being built for. Please look at kernel parameter tuning guide for Debian #
# 11_6_0 as this is only baseline hardening guide created on very specific #
# requirement due to the time constraint on bringing all systems back up   #
# in a very limited time. Please check with Bhaskar Roy & Rick Torres Jr.  #
# before making further changes to this.                                   #
# Author: broy@ibm.com                                                     #
# Config: /etc/ssh/sshd_config                                             #
############################################################################

SCTL="/etc/sysctl.d/99-sysctl.conf"
LCTL="/etc/sysctl.d/local-sysctl.conf"

# Add any additional kernel here settings as needed
PARAMS=(
"dev.tty.ldisc_autoload = 0"
"fs.protected_fifos = 2"
"kernel.core_uses_pid = 1"
"kernel.kptr_restrict = 2"
"kernel.sysrq = 0"
"kernel.unprivileged_bpf_disabled = 1"
"kernel.yama.ptrace_scope = 2"
"net.core.bpf_jit_harden = 2"
"net.ipv4.conf.all.log_martians = 1"
"net.ipv4.conf.all.rp_filter = 1"
"net.ipv4.conf.all.send_redirects = 0"
"net.ipv4.conf.default.accept_redirects = 0"
"net.ipv4.conf.default.accept_source_route = 0"
"net.ipv4.conf.default.log_martians = 1"
)

if [ -L ${SCTL} ]; then
  for PARAM in "${PARAMS[@]}"; do
    if [ $(grep -c "${PARAM}" ${SCTL}) -eq 0 ]; then
      echo "${PARAM}" >> ${LCTL}
    else
      sed -ie "s/^#.*${PARAM}/${PARAM}/g" ${SCTL}
    fi
  done
fi

# Fix REDBleed warning
