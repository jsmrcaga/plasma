#!/bin/bash

set -e

USER_LOCALE=${1:-'en_US.UTF-8'}

# -f to prevent failure if the file does not exist
rm -f /etc/locale.gen

echo -e "$USER_LOCALE UTF-8" > "/etc/locale.gen"

export LANGUAGE="$USER_LOCALE"
export LANG="$USER_LOCALE"
export LC_ALL="$USER_LOCALE" 2> /dev/null

locale-gen

update-locale LC_ALL="$USER_LOCALE"
