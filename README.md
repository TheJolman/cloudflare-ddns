# Cloudflare DDNS Service

This repo contains everything you need to get a simple DDNS service running for your home server using the Cloudflare API.

It automatically updates your Cloudflare DNS records with your current public IPv4 and IPv6 addresses. We use systemd's encrypted credentials feature to store API tokens and identifiers.

## Quick Start

1. Ensure you have `xh` and `jq` installed and are on a system with systemd.
2. Create `A` and `AAAA` records on the Cloudflare dash or with the API. These can have any value for now.
1. Obtain the following:
   - Record ID for aforementioned `A` and `AAAA` records. You can find these with `list_records.sh` or by manually using the Cloudflare API.
   - Cloudflare zone ID for your domain (you can find this in the Cloudflare dash).
   - Cloudflare Account API token with the Zone.DNS permissions.
   - An ipinfo.io API key (this is needed since we're grabbing both IPv4 and IPv6 IPs).
1. Run `sudo make set-secrets` and paste the required variables.
1. Run `sudo make install`.

## Useful commands

watch logs:
```bash
sudo journalctl -u cloudflare-ddns.service -f
systemctl status cloudflare-ddns.timer
systemctl status cloudflare-ddns.service  # NOTE: This probably won't be active since it gets started/stopped by the timer
```

check service status:
```bash
systemctl status cloudflare-ddns.timer
systemctl status cloudflare-ddns.service  # NOTE: This probably won't be active since it gets started/stopped by the timer
```

## Uninstall
```bash
sudo make uninstall
```

## Components

1. **cloudflare-ddns** - Bash script that fetches current IP and updates DNS records
2. **cloudflare-ddns.service** - Systemd service unit (oneshot)
3. **cloudflare-ddns.timer** - Systemd timer (runs every 2 minutes)
4. **Encrypted Credentials** - Stored in `/etc/cloudflare-ddns/`

## Timer Schedule

- **OnBootSec=1min**: First run 1 minute after system boot
- **OnUnitActiveSec=2min**: Subsequent runs every 2 minutes after previous completion


## Modifying Update Frequency

Edit `cloudflare-ddns.timer` and change `OnUnitActiveSec=` value:
```bash
sudo systemctl edit cloudflare-ddns.timer
sudo systemctl daemon-reload
sudo systemctl restart cloudflare-ddns.timer
```

## Only Update IPv4
You may wish to only expose/update your IPv4 address. In this case, you just have to delete the second function call in the main `cloudflare-ddns` script.
```diff
update_dns_record 'v4' "$CF_RECORD_ID_4"
-update_dns_record 'v6' "$CF_RECORD_ID_6"
```

## References

- [systemd.exec - LoadCredentialEncrypted](https://www.freedesktop.org/software/systemd/man/systemd.exec.html#LoadCredentialEncrypted=ID:PATH)
- [systemd-creds (freedesktop.org)](https://www.freedesktop.org/software/systemd/man/systemd-creds.html)
- [systemd-creds (systemd.io)](https://systemd.io/CREDENTIALS/)
- [Cloudflare DNS API](https://developers.cloudflare.com/api/operations/dns-records-for-a-zone-patch-dns-record)
- [Helpful blog post](https://congrong.wang/blog/setting-up-dynamic-dns-through-cloudflare/)
