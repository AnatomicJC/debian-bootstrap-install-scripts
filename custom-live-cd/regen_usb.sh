#!/usr/bin/env bash

export disk=/dev/sdz

sudo mkdir -p /mnt/{usb,efi}

sudo parted --script $disk \
    mklabel gpt \
    mkpart primary fat32 2048s 4095s \
        name 1 BIOS \
        set 1 bios_grub on \
    mkpart ESP fat32 4096s 413695s \
        name 2 EFI \
        set 2 esp on \
    mkpart primary fat32 413696s 100% \
        name 3 LINUX \
        set 3 msftdata on

sudo gdisk $disk << EOF
r     # recovery and transformation options
h     # make hybrid MBR
1 2 3 # partition numbers for hybrid MBR
N     # do not place EFI GPT (0xEE) partition first in MBR
EF    # MBR hex code
N     # do not set bootable flag
EF    # MBR hex code
N     # do not set bootable flag
83    # MBR hex code
Y     # set the bootable flag
x     # extra functionality menu
h     # recompute CHS values in protective/hybrid MBR
w     # write table to disk and exit
Y     # confirm changes
EOF

sudo mkfs.vfat -F32 ${disk}2 && \
sudo mkfs.vfat -F32 ${disk}3

sudo grub-install \
    --target=x86_64-efi \
    --efi-directory=/mnt/efi \
    --boot-directory=/mnt/usb/boot \
    --removable \
    --recheck

sudo grub-install \
    --target=i386-pc \
    --boot-directory=/mnt/usb/boot \
    --recheck \
    $disk

sudo mkdir -p /mnt/usb/{boot/grub,live}

sudo cp -r $HOME/LIVE_BOOT/image/* /mnt/usb/

sudo cp \
    $HOME/LIVE_BOOT/scratch/grub.cfg \
    /mnt/usb/boot/grub/grub.cfg

sudo umount /mnt/{usb,efi}
