# Variables
DISK=/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi0
HOSTNAME=server
DOMAIN=local
FQDN=${HOSTNAME}.${DOMAIN}
PUBLIC_IP=127.0.1.1
# IFACE_NAME will be dhcp, adapt script for your needs
IFACE_NAME=eth0

# Script
echo "deb http://ftp.debian.org/debian stretch main contrib" > /etc/apt/sources.list
apt update
apt install --yes debootstrap gdisk dpkg-dev linux-headers-$(uname -r) cryptsetup vim
apt install --yes zfs-dkms
modprobe zfs

apt install --yes mdadm
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

# cryptsetup
cryptsetup luksFormat ${DISK}-part1
cryptsetup luksOpen ${DISK}-part1 crypt_disk

zpool create -o ashift=12 \
      -O sync=disabled -O dedup=on \
      -O atime=off -O canmount=off -O compression=lz4 -O normalization=formD \
      -O xattr=sa -O mountpoint=/ -R /mnt \
      rpool /dev/mapper/crypt_disk

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

mke2fs -t ext2 ${DISK}-part4
mkdir /mnt/boot
mount ${DISK}-part4 /mnt/boot

chmod 1777 /mnt/var/tmp
debootstrap stretch /mnt
zfs set devices=off rpool

echo ${HOSTNAME} > /mnt/etc/hostname

cat >> /mnt/etc/hosts << EOF
127.0.1.1       ${HOSTNAME}
or if the system has a real name in DNS:
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
auto eth0
iface eth0 inet static
    address 173.212.242.218
    netmask 255.255.255.0
    gateway 173.212.242.1
    dns-search invalid
    dns-nameservers 213.136.95.11 213.136.95.10

    # add additional IP addresses this way
    # up ip address add xxx.xxx.xxx.xxx/XX dev eth0

iface eth0 inet6 static
    address 2a02:c207:2023:7453:0000:0000:0000:0001
    netmask 64
    gateway fe80::1
    accept_ra 0
    autoconf 0
    privext 0

# Set route to network
up ip route add 173.212.242.0/24 via 173.212.242.1
EOF

cat >> /mnt/etc/apt/sources.list << EOF
deb http://deb.debian.org/debian stretch-backports main
deb http://deb.debian.org/debian stretch main contrib non-free
deb http://deb.debian.org/debian stretch-updates main contrib non-free
deb http://deb.debian.org/debian-security stretch/updates main contrib non-free
EOF

mount --rbind /dev  /mnt/dev
mount --rbind /proc /mnt/proc
mount --rbind /sys  /mnt/sys

cp zfs_chroot.sh /mnt/
chmod +x /mnt/zfs_chroot.sh
chroot /mnt ./zfs_chroot.sh

mount | grep -v zfs | tac | awk '/\/mnt/ {print $3}' | xargs -i{} umount -lf {}
zpool export rpool
