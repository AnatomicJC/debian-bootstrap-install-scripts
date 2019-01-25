sudo apt-get install \
    debootstrap \
    squashfs-tools \
    xorriso \
    grub-pc-bin \
    grub-efi-amd64-bin \
    mtools

mkdir $HOME/LIVE_BOOT

sudo debootstrap --variant=minbase stretch $HOME/LIVE_BOOT/chroot http://deb.debian.org/debian
sudo cp setup-chroot.sh $HOME/LIVE_BOOT/chroot/
sudo chmod +x $HOME/LIVE_BOOT/chroot/setup-chroot.sh
sudo chroot $HOME/LIVE_BOOT/chroot /bin/bash -c /setup-chroot.sh
