#!/bin/bash

set -e

# Allow no files in directories
shopt -s nullglob

# Run pre-hooks
for file in /plasma/pre-hooks.d/*.sh; do
  bash "$file"
done

for source in /plasma/pre-hooks.d/*.env.sh; do
  source "$source"
done

# Run plasma init commands
for file in /plasma/init.d/*.sh; do
  bash "$file"
done

# Run post-hooks
for file in /plasma/post-hooks.d/*.sh; do
  bash "$file"
done

for source in /plasma/post-hooks.d/*.env.sh; do
  source "$source"
done

shopt -u nullglob

## Start container

# Start dbus for X and Sunshine
# TODO: run as user
dbus-daemon --system

# Input magic
# TODO: run as root
/lib/systemd/systemd-udevd --daemon

# For debugging but not necessary for running sunshine:
# udevadm monitor &
# udevadm trigger &

# Start X server
# Credit for all flags to Josh5
/usr/bin/Xorg \
    -ac \
    -noreset \
    -novtswitch \
    -sharevts \
    +extension RANDR \
    +extension RENDER \
    +extension GLX \
    +extension XVideo \
    +extension DOUBLE-BUFFER \
    +extension SECURITY \
    +extension DAMAGE \
    +extension X-Resource \
    -extension XINERAMA -xinerama \
    +extension Composite +extension COMPOSITE \
    -dpms \
    -s off \
    -nolisten tcp \
    -iglx \
    -verbose \
    vt7 "${DISPLAY:?}" &

# Start sunshine
sunshine
