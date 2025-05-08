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

# Run plasma runtime init commands
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

# Start supervisor in daemon mode
# And manually start services because of dependencies

# -c /etc/supervisor/supervisord.conf is implicit
supervisord --user root

## Bootstrap
supervisorctl start udev  # runs as root
supervisorctl start dbus
supervisorctl start xorg
supervisorctl start pulseaudio

## Apps
supervisorctl start steam
supervisorctl start sunshine
