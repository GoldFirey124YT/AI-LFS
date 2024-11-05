#!/bin/bash

# Update the system and install required packages
echo "Updating system and installing essential packages..."
sudo pacman -Syu --noconfirm
sudo pacman -S --needed --noconfirm \
    bash binutils bison bzip2 coreutils diffutils findutils \
    gawk gcc glibc grep gzip make patch perl sed tar texinfo \
    xz util-linux

# Set up the LFS variable
echo "Setting up LFS environment variable..."
export LFS=/mnt/lfs
echo "export LFS=/mnt/lfs" >> ~/.bashrc

# Create LFS directories
echo "Creating LFS directories..."
sudo mkdir -pv $LFS/{sources,tools}
sudo chmod -v a+wt $LFS/sources

# Mount the LFS partition
read -p "Enter the LFS partition (e.g., /dev/sdX1): " lfs_partition
sudo mount -v $lfs_partition $LFS

# Mount /dev, /proc, /sys, and /run to the LFS environment
echo "Mounting /dev, /proc, /sys, and /run..."
sudo mount -v --bind /dev $LFS/dev
sudo mount -vt devpts devpts $LFS/dev/pts -o gid=5,mode=620
sudo mount -vt proc proc $LFS/proc
sudo mount -vt sysfs sysfs $LFS/sys
sudo mount -vt tmpfs tmpfs $LFS/run

# Download the LFS book and sources
echo "Downloading the LFS book and source files..."
wget https://www.linuxfromscratch.org/lfs/downloads/stable/wget-list
wget https://www.linuxfromscratch.org/lfs/downloads/stable/md5sums
wget -P $LFS/sources -i wget-list
pushd $LFS/sources
md5sum -c ../md5sums
popd

# Add the LFS user and set up environment
echo "Creating the LFS user..."
sudo groupadd lfs
sudo useradd -s /bin/bash -g lfs -m -k /dev/null lfs
echo "Set a password for the 'lfs' user"
sudo passwd lfs
sudo chown -v lfs $LFS/{tools,sources}
sudo chmod -v a+wt $LFS/sources

# Set up environment for LFS user
cat << EOF | sudo tee -a /home/lfs/.bash_profile
exec env -i HOME=\$HOME TERM=\$TERM PS1='\u:\w\$ ' /bin/bash
EOF

cat << EOF | sudo tee -a /home/lfs/.bashrc
set +h
umask 022
LFS=/mnt/lfs
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/usr/bin
export LFS LC_ALL LFS_TGT PATH
export MAKEFLAGS="-j$(nproc)"
EOF

# Switch to LFS user and enter chroot environment for building LFS
echo "Switch to the 'lfs' user and enter chroot to start building LFS."
echo "Run 'su - lfs' to continue the installation manually by following the LFS book."
