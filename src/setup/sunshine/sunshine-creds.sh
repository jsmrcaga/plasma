#!/bin/bash
set -e

# This script should run in the Dockerfile

source "/plasma/setup/init/print.sh"

SUNSHINE_USERNAME=$1
SUNSHINE_PASSWORD=$2

if [[ -n "$SUNSHINE_USERNAME" && -n "$SUNSHINE_PASSWORD" ]]; then
	console_info "Setting Sunshine credentials for user: $SUNSHINE_USERNAME"
	sunshine --creds "$SUNSHINE_USERNAME" "$SUNSHINE_PASSWORD"
else
	console_warning "Sunshine: no username and password"
fi
