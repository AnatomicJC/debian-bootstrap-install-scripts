#!/bin/bash
# Variables
DISKS=( 
  /dev/disk/by-id/ata-VBOX_HARDDISK_VB1587128e-72f375b7
  )
DEBIAN_RELEASE=buster
HOSTNAME=server
DOMAIN=local
FQDN=${HOSTNAME}.${DOMAIN}
PUBLIC_IP=127.0.1.1
# IFACE_NAME will be dhcp, adapt script for your needs
IFACE_NAME=enp0s3
CRYPTED_DISKS="/dev/mapper/crypt_disk_0"

# Script
echo "deb http://ftp.debian.org/debian ${DEBIAN_RELEASE} main contrib" > /etc/apt/sources.list
apt update
apt install --yes debootstrap gdisk cryptsetup vim

apt install --yes mdadm

echo "Drop and recreate partitions"
for DISK in "${DISKS[@]}"
do
  mdadm --zero-superblock --force ${DISK}

  sgdisk --zap-all ${DISK}

  # Legacy BIOS
  sgdisk -a1 -n2:34:2047  -t2:EF02 ${DISK}
  # UEFI
  sgdisk     -n3:1M:+512M -t3:EF00 ${DISK}
  # Boot partition
  sgdisk     -n4:0:+512M  -t4:8300 ${DISK}
  # Fill free disk space
  sgdisk     -n1:0:0      -t1:8300 ${DISK}
done

echo "Cryptsetup"
COUNT=0
# cryptsetup
for DISK in "${DISKS[@]}"
do
  echo "cryptsetup luksFormat ${DISK}-part1"
  cryptsetup luksFormat ${DISK}-part1
  echo "cryptsetup luksOpen ${DISK}-part1 crypt_disk_${COUNT}"
  cryptsetup luksOpen ${DISK}-part1 crypt_disk_${COUNT}
  ((COUNT++))
done

mkfs.ext4 ${CRYPTED_DISKS}
mount ${CRYPTED_DISKS} /mnt/
mkdir /mnt/tmp

chmod 1777 /mnt/tmp

COUNT=0
for DISK in "${DISKS[@]}"
do
  APPEND=""
  if [ ${COUNT} -gt 0 ]
  then
    APPEND=${COUNT}
  fi
  mke2fs -t ext2 ${DISK}-part4
  mkdir /mnt/boot${APPEND}
  mount ${DISK}-part4 /mnt/boot${APPEND}
  ((COUNT++))
done

mkdir -p /mnt/var/tmp
chmod 1777 /mnt/var/tmp
debootstrap ${DEBIAN_RELEASE} /mnt

echo ${HOSTNAME} > /mnt/etc/hostname

cat >> /mnt/etc/hosts << EOF
127.0.1.1       ${HOSTNAME}
${PUBLIC_IP}       ${FQDN} ${HOSTNAME}

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

#cat >> /mnt/etc/network/interfaces.d/${IFACE_NAME} << EOF
#auto ${IFACE_NAME}
#iface ${IFACE_NAME} inet dhcp
#EOF
cat >> /mnt/etc/network/interfaces.d/${IFACE_NAME} << EOF
# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto ${IFACE_NAME}
iface ${IFACE_NAME} inet dhcp
EOF

cat >> /mnt/etc/apt/sources.list << EOF
deb http://deb.debian.org/debian ${DEBIAN_RELEASE}-backports main
deb http://deb.debian.org/debian ${DEBIAN_RELEASE} main contrib non-free
deb http://deb.debian.org/debian ${DEBIAN_RELEASE}-updates main contrib non-free
deb http://deb.debian.org/debian-security ${DEBIAN_RELEASE}/updates main contrib non-free
EOF

mount --rbind /dev  /mnt/dev
mount --rbind /proc /mnt/proc
mount --rbind /sys  /mnt/sys

cp ext4_chroot.sh /mnt/
chmod +x /mnt/ext4_chroot.sh
chroot /mnt ./ext4_chroot.sh

echo "Debug before umount ?"
bash
