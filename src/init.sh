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

# Start sunshine
exec supervisord -c /etc/supervisord/supervisord.conf --nodaemon --user root
