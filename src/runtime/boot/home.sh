#!/bin/bash

set -e

DONE_FILE="/home/$USER/.plasma.done"

function copy_home() {
	if [[ -f $DONE_FILE ]]; then
		console_info "Home already configured, running with existing files"
		return
	fi

	cp -a /home/default/. /home/$USER
	chown -R $USER:$USER /home/$USER
	rm -r /home/default
	touch $DONE_FILE
	console_ok "Home configured"
}

copy_home
