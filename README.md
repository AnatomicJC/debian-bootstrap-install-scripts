## ZFS Install Scripts

This repository contains script to configure ZFS full-encrypted as root filesystem.

Ressources:

* https://github.com/zfsonlinux/zfs/wiki/Debian-Stretch-Root-on-ZFS
* https://github.com/zfsonlinux/zfs/wiki/Ubuntu

#### How-to

1. Boot on a custom live-cd
2. Install Debian and ZFS with debootstrap

#### I have no IPMI/IDRAC/other access !! I can't use a live-CD !!

No problem, I already setup ZFS root encrypted system on cheaper dedibox servers, or low-cost VPS. We can use Grub to load a live-CD

### Boot on live-CD from Grub

On an already-installed system you want erase to re-install, you can add a custom entry to `/etc/grub.d/40_custom` file:

```
#!/bin/sh
exec tail -n +3 $0
# This file provides an easy way to add custom menu entries.  Simply type the
# menu entries you want to add after this comment.  Be careful not to change
# the 'exec tail' line above.
menuentry "Debian Live Stretch" {
    insmod loopback
    insmod iso9660
    set isopath="/iso"
    set isoname="debian-custom.iso"
    set isofile="${isopath}/${isoname}"
    loopback loop $isofile
    linux ${isopath}/vmlinuz boot=live findiso=${isofile} config hooks=filesystem username=live noeject toram=filesystem.squashfs
    initrd ${isopath}/initrd
}
```

**Caveats:** 

* This will work if you create a `/boot/iso` folder.
* You have to put in `/boot/iso` a debian-custom.iso (the debian live ISO), initrd and vmlinuz files.
* You will find `initrd` and `vmlinuz` files on your live-CD
* When grub is loaded, `/boot` folder is the root path, that's why **isopath** value is `/iso`

### Create a minimalist custom Debian live-CD

On some already-installed systems, you cannot put the 2 GB Debian live-cd. That's why you will need a smaller, and minimalist one.

Steps to create a minimalist CD: (don't execute these scripts as root user, they already contains sudo commands when it is needed):

    cd custom-live-cd

Setup your environment by installing some packages and create chroot of your CD:

    bash setup-env.sh

At least, generate you live-cd:

    bash regen_iso.sh

We don't need this, but you can also create a live-USB.

    bash regen_usb.sh

You will find your custom Debian live-cd on `~/LIVE_BOOT` and **vmlinuz** and **initrd** files on `~/LIVE_BOOT/image`

### Boot on live-cd and reinstall Debian with encrypted root ZFS filesystem

Copy zfs-install-scripts folder to your running live-cd instance.

There is some variables to be defined on top of both scripts:

* DISK: full path of your disk in `/dev/disk/by-id`, eg. `/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi0`. 
* PUBLIC_IP: it is the public IP of the main interface
* IFACE_NAME: systemd-named of your network card, eg. ens18, enps0f1, etc.

**Caveats:**

* Only one disk is supported for now. For RAID configurations, you will have to customize the script. Read the ZFS wiki pages
