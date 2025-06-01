#!/bin/bash

set -e

STDOUT="/var/log/setup-amd.plasma.log"
STDERR="/var/log/setup-amd.plasma.error"

gcn_version=""

if [[ -z $AMD_GCN_VERSION ]]; then
	echo "No GCN version detected. Will use newer version" >> $STDOUT
else
	gcn_version=$AMD_GCN_VERSION
fi

driver_package="xserver-xorg-video-amdgpu"
xorg_config="/plasma/config/amd/xorg.amdgpu.conf"
if [[ $gcn_version == "1.1" || $gcn_version == "1.0" ]]; then
  echo "GCN Version is: $gcn_version; using xserver-xorg-video-ati" >> $STDOUT
  echo "GCN Version is: $gcn_version; using xorg.radeon.conf in /etc/X11/xorg.conf" >> $STDOUT
  xorg_config="/plasma/config/amd/xorg.radeon.conf"
  driver_package="xserver-xorg-video-ati"
else
  echo "GCN Version is: $gcn_version; using xserver-xorg-video-amdgpu" >> $STDOUT
  echo "GCN Version is: $gcn_version; using xorg.amdgpu.conf in /etc/X11/xorg.conf" >> $STDOUT
fi

# Install drivers
dpkg --add-architecture i386
apt-get update
apt-get install -y --no-install-recommends \
	$driver_package \
	firmware-amd-graphics \
	libglx-mesa0 \
	libglx-mesa0:i386 \
	libgl1-mesa-dri \
	libgl1-mesa-dri:i386 \
	mesa-vulkan-drivers:i386 \
	mesa-vulkan-drivers 1> $STDOUT 2> $STDERR
	# radeontop \
	# libvulkan1 \
	# libvulkan1:i386 \
	# vulkan-tools

# Clean up
apt-get clean autoclean -y && \
	apt-get autoremove -y && \
	rm -rf /var/lib/apt/lists/*


# Copy necessary config
cp $xorg_config "/etc/X11/xorg.conf"
