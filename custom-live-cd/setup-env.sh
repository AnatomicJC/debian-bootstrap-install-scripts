#!/usr/bin/env bash

DEBIAN_RELEASE=buster

if [ ! -z ${1} ]
then
    DEBIAN_RELEASE="${1}"
fi

sudo apt-get install \
    debootstrap \
    squashfs-tools \
    xorriso \
    grub-pc-bin \
    grub-efi-amd64-bin \
    mtools

sudo rm -rf ${HOME}/LIVE_BOOT
mkdir -p ${HOME}/LIVE_BOOT

sudo debootstrap --variant=minbase ${DEBIAN_RELEASE} ${HOME}/LIVE_BOOT/chroot http://deb.debian.org/debian
sudo cp setup-chroot.sh ${HOME}/LIVE_BOOT/chroot/
sudo chmod +x ${HOME}/LIVE_BOOT/chroot/setup-chroot.sh
sudo chroot ${HOME}/LIVE_BOOT/chroot /bin/bash -c /setup-chroot.sh
