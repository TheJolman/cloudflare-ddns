#!/usr/bin/env bash

set -euo pipefail

secret_name=$1

systemd-creds encrypt --name="$secret_name" "$secret_name".txt /etc/cloudflare-ddns/"$secret_name".cred
