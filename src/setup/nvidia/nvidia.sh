#!/bin/bash

set -e

DRIVER_MAJOR_VERSION=$(echo ${NVIDIA_DRIVER_VERSION:?} | awk -F '.' '{print $1}')

if [[ $DRIVER_MAJOR_VERSION -lt 500 ]]; then
  NO_KERNEL_MODULE_FLAG="--no-kernel-module"
else
  NO_KERNEL_MODULE_FLAG="--no-kernel-modules"
fi

# Install Nvidia dependencies
apt-get update && apt-get install -y \
  linux-headers-amd64 \
  libglvnd-dev \
  kmod \
  wget \
  pkg-config

apt-get clean autoclean -y && \
  apt-get autoremove -y && \
  rm -rf /var/lib/apt/lists/* /var/tmp/*

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
    --no-install-libglvnd \
    1> /var/log/nvidia-setup.plasma.log \
    2> /var/log/nvidia-setup.plasma.error


rm /tmp/NVIDIA_DRIVERS.run

# Patch nvidia library
# Using source to run in the same process
source "/plasma/setup/nvidia/nvidia-nvenc-nvfbc.patch.sh"
