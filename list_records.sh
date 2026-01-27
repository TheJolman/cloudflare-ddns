#!/usr/bin/env bash

xh GET "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records/" \
    -A bearer --auth "$CF_API_TOKEN" || {
        echo 'Failed to list DNS records :(' >&2
    }
