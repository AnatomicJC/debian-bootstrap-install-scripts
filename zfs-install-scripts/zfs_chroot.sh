DISK=/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi0

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

echo UUID=$(blkid -s UUID -o value \
      ${DISK}-part4) \
      /boot ext2 noatime 0 2 >> /etc/fstab

echo crypt_disk UUID=$(blkid -s UUID -o value \
      ${DISK}-part1) none \
      luks,discard,initramfs > /etc/crypttab

sed -i 's/\(.*\)CRYPTSETUP=\(.*\)/CRYPTSETUP=y/g' /etc/cryptsetup-initramfs/conf-hook

apt install --yes grub-pc

if [ -d /sys/firmware/efi ]
then
  apt install --yes dosfstools
  mkdosfs -F 32 -n EFI ${DISK}-part3
  mkdir /boot/efi
  echo PARTUUID=$(blkid -s PARTUUID -o value \
      ${DISK}-part3) \
      /boot/efi vfat noatime,nofail,x-systemd.device-timeout=1 0 1 >> /etc/fstab
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
