#!/bin/bash

set -e

# Most of this has already happened during startup
# But we re-run these _just before_ booting to make
# sure all services and locations are properly configured

# Inputs
mkdir -p /var/run/dbus
chown -R ${USERNAME}:${USERNAME} /var/run/dbus/
chmod -R 770 /var/run/dbus/

# Looks like uinput is a file
touch -a /dev/uinput
chmod 0666 /dev/uinput

# Xorg
# - nothing here

# pulseaudio
mkdir -p /tmp/pulse
chown -R ${USERNAME}:${USERNAME} /tmp/pulse
chmod -R 770 /tmp/pulse

# Home permissions
chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}
