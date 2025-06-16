#!/bin/bash
set -e

dirname="$( cd "$( dirname "$(readlink -f "$0")" )" &> /dev/null && pwd )"
source "$dirname/setup/init/print.sh"

# Allow no files in directories
shopt -s nullglob

console_info "Configuring Home, copying files from /home/default to /home/$USER"
source /plasma/runtime/boot/home.sh
console_ok "Home files copied!"

# Run pre-hooks
console_info "Running Pre-init scripts"

for file in /plasma/pre-hooks.d/*.sh; do
  console_debug "Running $file..."
  bash "$file"
done
console_ok "Pre-init scripts done"

# Run plasma runtime init commands
console_info "Running Init scripts"
for file in /plasma/init.d/*.sh; do
  console_debug "Running $file..."
  bash "$file"
done
console_ok "Init scripts done"

# Run post-hooks
console_info "Running Post-init scripts"
for file in /plasma/post-hooks.d/*.sh; do
  bash "$file"
done
console_ok "Post-init scripts done"

shopt -u nullglob


# Sanity script before running services
console_info "Running Sanity check script"
/plasma/runtime/boot/sanity.sh
console_ok "Sanity OK"

console_success "All systems go. Starting processes..."
# -c /etc/supervisor/supervisord.conf is implicit
supervisord --user root

## Bootstrap
supervisorctl start udev  # runs as root
supervisorctl start dbus
supervisorctl start xorg
supervisorctl start pulseaudio

## Apps
# We want sunshine before steam
supervisorctl start sunshine
supervisorctl start wm

if [[ -n $GPU_PRIME ]]; then
  console_info "Priming with glmark2..."
  supervisorctl start glmark2
  console_info "Stopping glmark2..."
  supervisorctl stop glmark2
fi
supervisorctl start steam

# Send notification stating that Plasma is now ready to use
source /plasma/runtime/boot/notifications.sh

echo '
                                           0000000000
                                 000   0000000000000000000
                              0000  0000000000000000000000000
                            0000  00000000000000000000000000000
                          00000 000000000000000000000000000000000        0000000000000000
                         00000 000000000          000000000000000000000000000000000 000000
                       000000 0000000                 00000000000000            0000000000
                      000000 000000                     000000000000             0000000
                      00000  0000                         00000000000           000000
                     000000 0000                           00000000000        000000
                     000000 000                             0000000000     000000
                    0000000 00                               000000000  000000
                    0000000 00                               00000000000000
                    0000000 00                               00000000000
                   00000000 00                               000000000
               0000000000000                              00000000000
            000000  00000000                          000000000000000
         000000      00000000                    000000     00000000
      0000000        000000000              000000         00000000 0
    0000000           0000000000      0000000            00000000  00
  0000000              00000000000000000               000000000 000
 000000000             000000000000                  00000000  0000
000000 0000000000000000000000000000000    0000000000000000  00000
 000000000000000000        000000000000000              00000000
                             000000000000000000000000000000000
                               0000000000000000000000000000
                                  0000000000000000000000
                                        00000000000
'

if [[ -z $PLASMA_MANUAL ]]; then
  console_info "Staying alive!"
  # Hack to keep the container running
  tail -f /dev/null
fi
