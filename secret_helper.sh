#!/usr/bin/env bash

if [ $# -lt 1 ] || [  "$1" == '-h' ] || [ "$1" == '--help' ]; then
	echo "Usage: $0 <secret-name>"
	exit 0
fi

secret_name=$1

echo -n "Enter the value for $secret_name: "
read -r value
echo -n "$value" | systemd-creds encrypt --name="$secret_name" - "$secret_name"
