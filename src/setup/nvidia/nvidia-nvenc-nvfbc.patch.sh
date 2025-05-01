#!/bin/bash
set -e

# Attribution to keylase and Josh5
# Josh5 seems to have copied the code from keylase and adapted it to run properly
# @see https://github.com/keylase/nvidia-patch/blob/39f21ee316e6740be2fb1350086c8086906529a0/docker-entrypoint.sh#L7
# @see https://github.com/Steam-Headless/docker-steam-headless/blob/14c770bce61db99c56592760c73c2ba454dab648/overlay/etc/cont-init.d/60-configure_gpu_driver.sh#L150

# This file runs at Docker build because
# The patches we can download already include versions of
# the drivers, so no need to check for host or connected GPU

# Version from April 29 2025 - Commit 39f21ee
# https://github.com/keylase/nvidia-patch/commit/39f21ee316e6740be2fb1350086c8086906529a0

# Download patch
# NVENC
wget -q --show-progress --progress=bar:force:noscroll \
	-O /plasma/setup/nvidia/nvenc-patch.sh \
	https://raw.githubusercontent.com/keylase/nvidia-patch/39f21ee316e6740be2fb1350086c8086906529a0/patch.sh
# NVFBC
wget -q --show-progress --progress=bar:force:noscroll \
	-O /plasma/setup/nvidia/nvfbc-patch.sh \
	https://raw.githubusercontent.com/keylase/nvidia-patch/39f21ee316e6740be2fb1350086c8086906529a0/patch-fbc.sh

chmod +x \
	/plasma/setup/nvidia/nvenc-patch.sh \
	/plasma/setup/nvidia/nvfbc-patch.sh

# Apply patch
# 1/ Load library patch into library loader
echo "/patched-nvidia-lib" > /etc/ld.so.conf.d/000-patched-lib.conf
mkdir -p "/patched-nvidia-lib"

# 2/ Run patches
PATCH_OUTPUT_DIR="/patched-nvidia-lib" /plasma/setup/nvidia/nvenc-patch.sh -d $NVIDIA_DRIVER_VERSION
PATCH_OUTPUT_DIR="/patched-nvidia-lib" /plasma/setup/nvidia/nvfbc-patch.sh -d $NVIDIA_DRIVER_VERSION

# Go to patch directory
pushd "/patched-nvidia-lib" &> /dev/null || { echo "Could not push directory /patched-nvidia-lib"; exit 1; }
# Run magic patches in /patched-nvidia-lib
for f in * ; do
    suffix="${f##*.so}"
    name="$(basename "$f" "$suffix")"
    [ -h "$name" ] || ln -sf "$f" "$name"
    [ -h "$name" ] || ln -sf "$f" "$name.1"
done

# Reload library config
ldconfig

# Go back to previous directory
popd &> /dev/null || { echo "Could not leave /patched-nvidia-lib directory"; exit 1; }

