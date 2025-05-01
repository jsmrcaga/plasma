#!/bin/bash

set -e

DRIVER_MAJOR_VERSION=$(echo ${NVIDIA_DRIVER_VERSION:?} | awk -F '.' '{print $1}')

if [[ $DRIVER_MAJOR_VERSION -lt 500 ]]; then
  NO_KERNEL_MODULE_FLAG="--no-kernel-module"
else
  NO_KERNEL_MODULE_FLAG="--no-kernel-modules"
fi

# Install Nvidia dependencies
apt-get install -y \
  linux-headers-amd64 \
  libglvnd-dev \
  kmod \
  wget \
  pkg-config

apt-get autoremove && apt-get clean

# Blacklsit nouveau
mkdir -p /etc/modprobe.d
echo "options nouveau modeset=0" > /etc/modprobe.d/blacklist-nouveau.conf

# Download driver
wget \
    -q --show-progress --progress=bar:force:noscroll \
    -O /tmp/NVIDIA_DRIVERS.run \
    http://download.nvidia.com/XFree86/Linux-x86_64/$NVIDIA_DRIVER_VERSION/NVIDIA-Linux-x86_64-$NVIDIA_DRIVER_VERSION.run

chmod +x /tmp/NVIDIA_DRIVERS.run

/tmp/NVIDIA_DRIVERS.run \
    --silent \
    --accept-license \
    --skip-depmod \
    --skip-module-unload \
    $NO_KERNEL_MODULE_FLAG \
    --no-kernel-module-source \
    --install-compat32-libs \
    --no-nouveau-check \
    --no-nvidia-modprobe \
    --no-systemd \
    --no-distro-scripts \
    --no-rpms \
    --no-backup \
    --no-check-for-alternate-installs \
    --no-libglx-indirect \
    --no-install-libglvnd

rm /tmp/NVIDIA_DRIVERS.run
