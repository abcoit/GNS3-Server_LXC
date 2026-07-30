#!/bin/bash
# Install GNS3 to a LXC Debian 11 container
# Debian 11 Prerequisites: sudo
# Add into the LXC configuration file on Proxmox host (ie. /etc/pve/lxc/<id>.conf)
#lxc.cgroup.devices.allow: c 10:232 rwm
#lxc.cgroup2.devices.allow: c 10:232 rwm
# Also, check that nested and mknod are enabled:
#features: mknod=1,nesting=1
# Then, in LXC container, type: 
#mknod /dev/kvm c 10 232
#chmod 777 /dev/kvm
#chown root:kvm /dev/kvm
# Create sudoer user gns3, switch to it and run this script
#sudo adduser gns3
#sudo adduser gns3 sudo

mkdir "$HOME/build"
cd "$HOME/build"

#Install dependencies
sudo apt update
sudo apt install -y ufw git build-essential pcaputils libpcap-dev libelf-dev cmake subversion docker.io python3-pip python3-pyqt5 python3-pyqt5.qtsvg python3-pyqt5.qtwebsockets qemu qemu-kvm qemu-utils libvirt-clients libvirt-daemon-system virtinst wireshark xtightvncviewer apt-transport-https ca-certificates curl gnupg2 software-properties-common

#Install GNS3 server
sudo pip3 install gns3-server
sudo pip3 install gns3-gui

#UBridge
git clone https://github.com/GNS3/ubridge.git
cd ubridge
make 
sudo make install
cd -

#Dynamips
git clone https://github.com/GNS3/dynamips.git
cd dynamips
mkdir build
cd build
cmake ..
sudo make install
cd -

#VPCS
svn checkout svn://svn.code.sf.net/p/vpcs/code/trunk vpcs-code
cd vpcs-code/src
rgetopt='int getopt(int argc, char *const *argv, const char *optstr);'
sed -i "s/^int getopt.*/$rgetopt/" getopt.h
unset -v rgetopt
sed -i vpcs.h -e 's#pcs vpc\[MAX_NUM_PTHS\];#extern pcs vpc\[MAX_NUM_PTHS\];#g'
sed -i vpcs.c -e '/^static const char \*ident/a \\npcs vpc[MAX_NUM_PTHS];'
sed -i 's/i386/x86_64/' Makefile.linux
sed -i 's/-s -static//' Makefile.linux
make -f Makefile.linux
strip --strip-unneeded vpcs
sudo mv vpcs /usr/local/bin

#Add to groups
for i in ubridge docker wireshark kvm; do
 sudo usermod -aG $i $USER
done
