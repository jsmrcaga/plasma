USE_COLOR=${PLASMA_COLOR:-true}

function console_log {
	iso_date=$(date -Ins)
	if [[ $USE_COLOR == "true" ]]; then
		echo -e "${1}${2} ${3} \u001b[0m [$iso_date] ${@:4}"
	else
		echo -e "${3} | [$iso_date] ${@:4}"		
	fi
}

function console_info {
	console_log "\u001b[46;1m" "\u001b[38;5;16m" "INFO" ${@}
}

function console_error {
	console_log "\u001b[41;1m" "\u001b[38;5;15m" "ERROR" ${@}
}

function console_success {
	console_log "\u001b[42;1m" "\u001b[38;5;16m" "SUCCESS" ${@}
}

function console_ok {
	console_log "\u001b[42;1m" "\u001b[38;5;16m" "OK" ${@}
}

function console_warning {
	console_log "\u001b[43;1m" "\u001b[38;5;16m" "WARNING" ${@}
}

function console_debug {
	console_log "\u001b[48;5;242m" "\u001b[38;5;16m" "DEBUG" ${@}
}
