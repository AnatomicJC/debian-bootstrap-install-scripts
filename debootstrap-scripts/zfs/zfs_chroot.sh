#!/bin/bash
DISKS=( 
  /dev/disk/by-id/ata-VBOX_HARDDISK_VB1587128e-72f375b7
  /dev/disk/by-id/ata-VBOX_HARDDISK_VBaacf6245-82bc0762
  )

ln -s /proc/self/mounts /etc/mtab
apt update

echo "Set root passwd"
passwd

echo "Create kendo user"
useradd kendo
passwd kendo

apt install --yes locales tzdata ssh

apt install --yes dpkg-dev linux-headers-$(uname -r) linux-image-amd64 cryptsetup
apt install --yes zfs-dkms zfs-initramfs

COUNT=0
for DISK in "${DISKS[@]}"
do
  APPEND=""
  if [ ${COUNT} -gt 0 ]
  then
    APPEND=${COUNT}
  fi
  echo UUID=$(blkid -s UUID -o value \
        ${DISK}-part4) \
        /boot${APPEND} ext2 noatime 0 2 >> /etc/fstab
  
  echo crypt_disk_${COUNT} UUID=$(blkid -s UUID -o value \
        ${DISK}-part1) none \
        luks,discard,initramfs >> /etc/crypttab
  ((COUNT++))
done

sed -i 's/\(.*\)CRYPTSETUP=\(.*\)/CRYPTSETUP=y/g' /etc/cryptsetup-initramfs/conf-hook

apt install --yes grub-pc grub2

if [ -d /sys/firmware/efi ]
then
  apt install --yes dosfstools
  COUNT=0
  for DISK in "${DISKS[@]}"
  do
    APPEND=""
    if [ ${COUNT} -gt 0 ]
    then
      APPEND=${COUNT}
    fi
    mkdosfs -F 32 -n EFI ${DISK}-part3
    mkdir -p /boot/efi${APPEND}
    echo PARTUUID=$(blkid -s PARTUUID -o value \
        ${DISK}-part3) \
        /boot/efi${APPEND} vfat noatime,nofail,x-systemd.device-timeout=1 0 1 >> /etc/fstab
    ((COUNT++))
  done
  mount /boot/efi
  apt install --yes grub-efi-amd64

  grub-install --target=x86_64-efi --efi-directory=/boot/efi \
      --bootloader-id=debian --recheck --no-floppy
fi

zfs set mountpoint=legacy rpool/var/log
zfs set mountpoint=legacy rpool/var/tmp
cat >> /etc/fstab << EOF
rpool/var/log /var/log zfs noatime,nodev,noexec,nosuid 0 0
rpool/var/tmp /var/tmp zfs noatime,nodev,nosuid 0 0
EOF

zfs set mountpoint=legacy rpool/tmp
cat >> /etc/fstab << EOF
rpool/tmp /tmp zfs noatime,nodev,nosuid 0 0
EOF

update-initramfs -u -k all
update-grub
echo "Debug before quitting chroot ?"
bash
