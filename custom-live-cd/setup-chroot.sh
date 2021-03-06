#!/usr/bin/env bash

echo "debian-live" > /etc/hostname
apt-get install --yes --no-install-recommends linux-image-amd64 live-boot systemd-sysv ssh iproute2 iputils-ping isc-dhcp-client

cat >> /etc/resolv.conf << EOF
nameserver 8.8.8.8
EOF

cat >> /etc/rc.local << EOF
#!/bin/bash
dhclient
exit 0
EOF

chmod +x /etc/rc.local

cat >> /etc/systemd/system/rc-local.service << EOF
[Unit]
 Description=/etc/rc.local Compatibility
 ConditionPathExists=/etc/rc.local

[Service]
 Type=forking
 ExecStart=/etc/rc.local start
 TimeoutSec=0
 StandardOutput=tty
 RemainAfterExit=yes
 SysVStartPriority=99

[Install]
 WantedBy=multi-user.target
EOF

systemctl enable rc-local

echo "Set root password"
passwd root
mkdir /root/.ssh
cat >> /root/.ssh/authorized_keys << EOF
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO3IvjWAehtwskoS2Ofy7zKuhOaFH7yzShgV9zqwiH2f
EOF

rm -rf /var/cache
rm -rf /usr/share/{doc,locale,man}
rm -rf /var/lib/{apt,dpkg}

mkdir -p /var/lib/dpkg/{info,alternatives,updates}
touch /var/lib/dpkg/status
echo "== Debug =="
bash
