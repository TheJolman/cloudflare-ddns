#!/usr/bin/env bash

echo "Querying Cloudflare API to view DNS records..."
read -rsp "Enter your domain's zone ID: " CF_ZONE_ID
echo
read -rsp "Enter your Cloudflare API token: " CF_API_TOKEN

xh GET "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records/" \
    -A bearer --auth "$CF_API_TOKEN" || {
        echo 'Failed to list DNS records :(' >&2
    }
