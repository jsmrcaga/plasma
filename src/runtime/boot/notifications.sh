#!/bin/bash

set -e

if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
	console_debug "Telegram not configured"
	exit 0
fi

curl \
	https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage \
	-X POST \
	-H "Content-Type: application/json" \
	-d "{\"chat_id\":\"$TELEGRAM_CHAT_ID\", \"text\": \"Plasma is ready to use!\"}"
