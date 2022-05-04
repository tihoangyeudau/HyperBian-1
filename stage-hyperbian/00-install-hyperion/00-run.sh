#!/bin/bash -e

# Select the appropriate download path
HYPERION_DOWNLOAD_URL="https://github.com/tihoangyeudau/hyperion.ng-14/releases/download"
HYPERION_RELEASES_URL="https://api.github.com/repos/tihoangyeudau/hyperion.ng-14/releases"

# Get the latest version
HYPERION_LATEST_VERSION=$(curl -sL "$HYPERION_RELEASES_URL" | grep "tag_name" | head -1 | cut -d '"' -f 4)
HYPERION_RELEASE=$HYPERION_DOWNLOAD_URL/$HYPERION_LATEST_VERSION/Ambilight-WiFi-$HYPERION_LATEST_VERSION-Linux-armv6l.deb

# Download latest release
echo 'Downloading Ambilight WiFi ........................'
mkdir -p "$ROOTFS_DIR"/tmp
curl -L $HYPERION_RELEASE --output "$ROOTFS_DIR"/tmp/ambilightwifi.deb

# Download Rpi fan
echo 'Downloading Rpi fan ........................'
curl -sS -L --get https://github.com/tihoangyeudau/rpi-fan/releases/download/1.0.0/rpi-fan.tar.gz | tar --strip-components=0 -C ${ROOTFS_DIR}/usr/share/ rpi-fan -xz

# Copy service file
cp rpi-fan.service ${ROOTFS_DIR}/etc/systemd/system/rpi-fan@.service

# Enable SPI and force HDMI output
sed -i "s/^#dtparam=spi=on.*/dtparam=spi=on/" ${ROOTFS_DIR}/boot/config.txt
sed -i "s/^#hdmi_force_hotplug=1.*/hdmi_force_hotplug=1/" ${ROOTFS_DIR}/boot/config.txt

# Modify /usr/lib/os-release
sed -i "s/Raspbian/Rmlos/gI" ${ROOTFS_DIR}/usr/lib/os-release
sed -i "s/^NAME=.*$/NAME=\"Rmlos ${HYPERION_LATEST_VERSION}\"/g" ${ROOTFS_DIR}/usr/lib/os-release
sed -i "s/^VERSION=.*$/VERSION=\"${HYPERION_LATEST_VERSION}\"/g" ${ROOTFS_DIR}/usr/lib/os-release
sed -i "s/^HOME_URL=.*$/HOME_URL=\"https:\/\/rainbowmusicled.com\/\"/g" ${ROOTFS_DIR}/usr/lib/os-release
sed -i "s/^SUPPORT_URL=.*$/SUPPORT_URL=\"https:\/\/rainbowmusicled.com\/\"/g" ${ROOTFS_DIR}/usr/lib/os-release
sed -i "s/^BUG_REPORT_URL=.*$/BUG_REPORT_URL=\"https:\/\/rainbowmusicled.com\/\"/g" ${ROOTFS_DIR}/usr/lib/os-release

# Custom motd
install -m 755 files/motd-rmlos "${ROOTFS_DIR}"/etc/update-motd.d/10-rmlos

# Remove the "last login" information
sed -i "s/^#PrintLastLog yes.*/PrintLastLog no/" ${ROOTFS_DIR}/etc/ssh/sshd_config

on_chroot << EOF
echo 'Installing Ambilight WiFi ........................'
apt-get update && apt-get -y install libglvnd0 && apt-get -y install /tmp/ambilightwifi.deb
rm /tmp/ambilightwifi.deb
echo 'Registering Ambilight WiFi & Rpi fan'
cp /usr/share/ambilightwifi/service/ambilightwifi.systemd /etc/systemd/system/ambilightwifi@.service
systemctl -q enable ambilightwifi"@rml".service
systemctl -q enable rpi-fan"@rml".service
EOF
