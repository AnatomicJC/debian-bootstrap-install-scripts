#!/bin/bash

. zfs.vars

echo "deb http://ftp.debian.org/debian ${DEBIAN_RELEASE} main contrib" > /etc/apt/sources.list
apt update
apt install --yes debootstrap gdisk dpkg-dev linux-headers-$(uname -r) cryptsetup vim

# After zfs-dkms install, an installation error
# can occur, due to postinst scripts :-(
apt install --yes zfs-dkms
# Installation can fail because zfs module is not loaded yet
# So load it
modprobe zfs
# Then be sure packages are correctly installed
apt-get -f install

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

# Sometimes, disks can not be ready for cryptsetup step
# So, Add a 2 seconds sleep...
sleep 2

# Script
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

zpool create -o ashift=12 \
      -O sync=${ZFS_SYNC} -O dedup=${ZFS_DEDUP} \
      -O atime=off -O canmount=off -O compression=lz4 -O normalization=formD \
      -O xattr=sa -O mountpoint=/ -R /mnt \
      rpool ${ZFS_RAID} ${ZFS_CRYPTED_DISKS}

zfs create -o canmount=off -o mountpoint=none rpool/ROOT
zfs create -o canmount=noauto -o mountpoint=/ rpool/ROOT/debian
zfs mount rpool/ROOT/debian

zfs create                 -o setuid=off              rpool/home
zfs create -o mountpoint=/root                        rpool/home/root
zfs create -o canmount=off -o setuid=off  -o exec=off rpool/var
zfs create -o com.sun:auto-snapshot=false             rpool/var/cache
zfs create                                            rpool/var/log
zfs create                                            rpool/var/spool
zfs create -o com.sun:auto-snapshot=false -o exec=on  rpool/var/tmp

zfs create -o mountpoint=/var/lib/docker              rpool/var/docker

zfs create -o com.sun:auto-snapshot=false \
             -o setuid=off                              rpool/tmp
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

chmod 1777 /mnt/var/tmp
debootstrap ${DEBIAN_RELEASE} /mnt
zfs set devices=off rpool

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

cp zfs_chroot.sh /mnt/
chmod +x /mnt/zfs_chroot.sh
chroot /mnt ./zfs_chroot.sh

echo "Debug before umount ?"
bash
mount | grep -v zfs | tac | awk '/\/mnt/ {print $3}' | xargs -i{} umount -lf {}
zpool export rpool
