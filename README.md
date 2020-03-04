## Debian bootstrap Install Scripts

In the beginning, this repository contained scripts to configure ZFS full-encrypted as root filesystem, because of deduplication feature.

Then Ext4 and XFS encrypted root filesystems were added.

XFS is now my first choice since I discovered [reflinks](https://gist.github.com/AnatomicJC/d51072e09f4f17c05042f639e7b1f4c6)

Ressources:

* https://github.com/zfsonlinux/zfs/wiki/Debian-Stretch-Root-on-ZFS
* https://github.com/zfsonlinux/zfs/wiki/Ubuntu
* https://gist.github.com/AnatomicJC/d51072e09f4f17c05042f639e7b1f4c6

#### How-to

1. Boot on a custom live-cd
2. Install Debian XFS/ZFS/Ext4 with debootstrap

#### I have no IPMI/IDRAC/other access !! I can't use a live-CD !!

No problem, I already setup root encrypted filesystems on cheaper dedibox servers, or low-cost VPS. We can use Grub to load a live-CD

### Boot on live-CD from Grub

On an already-installed system you want erase for re-install, you can add a custom entry to `/etc/grub.d/40_custom` file:

```
#!/bin/sh
exec tail -n +3 $0
# This file provides an easy way to add custom menu entries.  Simply type the
# menu entries you want to add after this comment.  Be careful not to change
# the 'exec tail' line above.
menuentry "Debian Live" {
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
* You have to put in `/boot/iso` a debian-custom.iso (the debian live ISO), `initrd` and `vmlinuz` files.
* You will find `initrd` and `vmlinuz` files on your live-CD
* When grub is loaded, `/boot` folder is the root path, that's why **isopath** value is `/iso`

### Create a minimalist custom Debian live-CD

Source: https://willhaley.com/blog/custom-debian-live-environment/

On some already-installed systems, you cannot put the 2 GB Debian live-cd. That's why you will need a smaller, and minimalist one.

Steps to create a minimalist CD: (don't execute these scripts as root user, they already contains sudo commands when it is needed):

    cd custom-live-cd

Setup your environment by installing some packages and create chroot of your CD:

    bash setup-env.sh

At least, generate your live-cd:

    bash regen_iso.sh

We don't need this, but you can also create a live-USB (not tested).

    bash regen_usb.sh

You will find your custom Debian live-cd on `~/LIVE_BOOT` and **vmlinuz** and **initrd** files on `~/LIVE_BOOT/image`

### Boot on live-cd and reinstall Debian with encrypted root filesystem

Copy `debootstrap-scripts` folder to your running live-cd instance.

There is some variables you have to defined in xfs, zfs or ext4 classes, depending on which filesystem you want to use.

* DISK: full path of your disk in `/dev/disk/by-id`, eg. `/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi0`. 
* PUBLIC_IP: it is the public IP of the main interface
* IFACE_NAME: systemd-named of your network card, eg. ens18, enps0f1, etc.
* .....

Once it is done, you can exec script:

    cd debootstrap-scripts
    bash script.sh [xfs|zfs|ext4]

Please enjoy....
