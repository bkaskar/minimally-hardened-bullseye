# minimally-hardened-bullseye

### In a disaster when you start from scratch with a freshly installed Debian system.
When time is of essence but even starting with ansible is not an option. The very first basic system, which can be a trustworthy baseline image, starts here. 
You can use these scripts to minimally harden the system creating a baseline image just to get up and running. These scripts quickly bring your template on a secure state where it is ready for a base role assignment, and then further fine-tuning can be done for performance improvement of the specific service while keeping the server secure. Follow [this document]() for initial install on direct hardware or VM that can be saved as a template.

A general case would be: 
  #. Installing Debian on Hardware/VM 
  #. Baseline hardening
  #. Creating a template for future use
  #. Using hardened template as required per role
  #. Re-hardening the template or already provisioned server
  #. Running audits and improving security score
  #. Comments on additional hardening (nice to have)

You can start at any of the stages above based on your current status. e.g. if you alrady have a system that is installed and you would like to just harden it, you start with baseline hardening but you may not need to create a template. If you just like to know your current state, just run a quick audit instead of the full CIS Benchmarks.

## Install Debian
### Initial install 
Follow [this document](TODO:) for initial install on direct hardware or VM that can be saved as a template.

## Baseline hardening
### Numbered hardening scripts

Run is the `00.harden_existing_system.sh`, which essentially calls all of the scripts from `01` to all the way till the last numeric. Make sure you sudo to root.
```
$ sudo su -
```
If you are logged in as non-priviledged user say `templateid` user, you need to enter templateid user's password. sudo many not be installed on a system, so you first need to install sudo at console (as root) and increase the user's basic privileges for now. 
``` 
# apt install sudo -y
```
In order to run an individual script just be in the base_hardening directory and run any
of the scripts individually i.e.
./04.update_kern_params.sh

If you have an Endpoint Detection and Response (i.e. CrowdStrike in this case), install the falcon sensor agent to make sure it reports into EDR. Make sure you have the customer ID handy for this install.
```
cd falcon_agent
./install.sh
```
#### Reboot the system  

Feel free to comment/discuss.
More on this:
* OpenSSH hardening
  [For most recent OS Versions](https://www.sshaudit.com/hardening_guides.html)
  [10 simple rules](https://linuxhandbook.com/ssh-hardening-tips/)
  [Linux-audit blog](https://linux-audit.com/audit-and-harden-your-ssh-configuration/)

* Systemd score improvement
  [working with systemd scores](https://www.opensourcerers.org/2022/04/25/optimizing-a-systemd-service-for-security/)
  [Systemd service hardening](https://www.linuxjournal.com/content/systemd-service-strengthening)
  [systemd_service_hardening](https://gist.github.com/ageis/f5595e59b1cddb1513d1b425a323db04)

* NFS Hardening
  Best place to start is RTFM.. 
  [TLDP basics](https://tldp.org/HOWTO/NFS-HOWTO/security.html)
  [Debian guidance](https://wiki.debian.org/SecuringNFS) 
  [Security Hardening website](http://www.securityhardening.com/library/Article14.pdf)
  [Cloud Infrastructure Services](https://cloudinfrastructureservices.co.uk/how-to-install-nfs-on-debian-11-server/)

* For a managed/mature environment (planned secure config program) check out konstruktoid/ansible-role-hardening
