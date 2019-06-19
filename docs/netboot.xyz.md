# Add netboot.xyz as grub boot menu

Download lkrn file:

```
wget https://boot.netboot.xyz/ipxe/netboot.xyz.lkrn -O /boot/ipxe.lkrn
```

Add to `/etc/grub.d/40_custom` file a linux16 type menuentry:

```
menuentry "Network boot (iPXE)" {
    linux16 /ipxe.lkrn
}
```

Then launch :

```
update-grub
```
