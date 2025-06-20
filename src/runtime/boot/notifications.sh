#!/bin/bash

set -e

if [[ -z "$TELEGRAM_CHAT_ID" ]]; then
	console_debug "Telegram not configured"
	exit 0
fi


if [[ -n "$TELEGRAM_BOT_TOKEN" ]]; then
	# We have a bot token
	text="Plasma is ready to use\\\\!"
	if [[ -n $HOST_IP ]]; then
		text+="\n\nConnect Connect Moonlight to\n\`$HOST_IP\`"
	fi
	curl \
		https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage \
		-X POST \
		-H "Content-Type: application/json" \
		-d "{\"chat_id\":\"$TELEGRAM_CHAT_ID\", \"text\": \"$text\", \"parse_mode\": \"MarkdownV2\"}"
	exit 0
fi

# We are using plasma-bot
host_ip_part=""
if [[ -n $HOST_IP ]]; then
	host_ip_part=", \"host_ip\":\"$HOST_IP\""
fi
content="{\"chat_id\":\"$TELEGRAM_CHAT_ID\"$host_ip_part}"

curl \
	https://plasma-bot.jocolina.com/api/plasma/ready \
	-X POST \
	-H "Content-Type: application/json" \
	-d "$content"
