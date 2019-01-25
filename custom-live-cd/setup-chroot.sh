echo "debian-live" > /etc/hostname
apt-get install --yes --no-install-recommends linux-image-amd64 live-boot systemd-sysv ssh
echo "Set root password"
passwd root
