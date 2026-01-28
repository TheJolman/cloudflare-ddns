# Cloudflare DDNS Service

This repo contains everything you need to get a simple DDNS service running for your home server using the Cloudflare API.

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

## Overview

This service automatically updates Cloudflare DNS records with your current public IPv4 and IPv6 addresses. It uses systemd's encrypted credentials feature to securely store API tokens and identifiers.

## Architecture

### Components

1. **cloudflare-ddns** - Bash script that fetches current IP and updates DNS records
2. **cloudflare-ddns.service** - Systemd service unit (oneshot)
3. **cloudflare-ddns.timer** - Systemd timer (runs every 2 minutes)
4. **Encrypted Credentials** - Stored in `/etc/cloudflare-ddns/`

### How Systemd Credentials Work

Systemd's `LoadCredentialEncrypted=` directive:
- Decrypts credentials at service start time
- Makes them available only to the service process
- Exposes them via `$CREDENTIALS_DIRECTORY` environment variable
- Each credential is a separate file in that directory

## Credential Flow

1. **Encryption** (`make set-secrets`):
   ```bash
   echo -n "value" | systemd-creds encrypt --name=NAME - OUTPUT_FILE
   ```
   Creates encrypted credential files in the current directory.

2. **Installation** (`make install`):
   Files are copied to `/etc/cloudflare-ddns/` with restrictive permissions (600, root:root).

3. **Service Start**:
   ```systemd
   LoadCredentialEncrypted=CF_ZONE_ID:/etc/cloudflare-ddns/CF_ZONE_ID
   ```
   Systemd decrypts and makes available at `$CREDENTIALS_DIRECTORY/CF_ZONE_ID`.

4. **Script Usage**:
   ```bash
   CF_ZONE_ID=$(cat "$CREDENTIALS_DIRECTORY/CF_ZONE_ID")
   ```
   Script reads plaintext credentials from the temporary directory.

## Required Credentials

| Variable | Purpose | How to Get |
|----------|---------|------------|
| `CF_ZONE_ID` | Cloudflare Zone ID | Dashboard → Domain → Overview → Zone ID |
| `CF_RECORD_ID_4` | IPv4 DNS Record ID | Use `list_records.sh` or API |
| `CF_RECORD_ID_6` | IPv6 DNS Record ID | Use `list_records.sh` or API |
| `CF_API_TOKEN` | Cloudflare API Token | Dashboard → Profile → API Tokens → Create Token |
| `IPINFO_API_TOKEN` | IPInfo API Token | https://ipinfo.io/account/token |

### API Token Permissions

The Cloudflare API token needs:
- **Zone.DNS** - Edit permissions
- **Zone Resources** - Include specific zones

## Installation

### 1. Encrypt Secrets
```bash
sudo make set-secrets
```
This creates encrypted credential files in the current directory.

### 2. Install Service
```bash
sudo make install
```
This:
- Copies encrypted credentials to `/etc/cloudflare-ddns/`
- Installs the script to `/usr/local/bin/`
- Installs systemd units to `/etc/systemd/system/`
- Enables and starts the timer

### 3. Verify
```bash
sudo journalctl -u cloudflare-ddns.service -f
```

## Management

### Check Status
```bash
systemctl status cloudflare-ddns.timer
systemctl status cloudflare-ddns.service
```

### View Logs
```bash
journalctl -u cloudflare-ddns.service
journalctl -u cloudflare-ddns.service -f  # follow
journalctl -u cloudflare-ddns.service --since "1 hour ago"
```

### Manual Trigger
```bash
sudo systemctl start cloudflare-ddns.service
```

### Disable/Enable
```bash
sudo systemctl disable cloudflare-ddns.timer  # stop automatic runs
sudo systemctl enable cloudflare-ddns.timer   # resume automatic runs
```

### Uninstall
```bash
sudo make uninstall
```

## Dependencies

- `systemd` with credentials support (systemd ≥ 250)
- `xh` - HTTP client (or replace with `curl`)
- `jq` - JSON processor

## Timer Schedule

- **OnBootSec=1min**: First run 1 minute after system boot
- **OnUnitActiveSec=2min**: Subsequent runs every 2 minutes after previous completion

## File Locations

| Component | Location |
|-----------|----------|
| Script | `/usr/local/bin/cloudflare-ddns` |
| Service Unit | `/etc/systemd/system/cloudflare-ddns.service` |
| Timer Unit | `/etc/systemd/system/cloudflare-ddns.timer` |
| Encrypted Credentials | `/etc/cloudflare-ddns/*` |

## Maintenance

### Updating Credentials

1. Generate new encrypted credentials: `sudo make set-secrets`
2. Reinstall: `sudo make install`
3. Service will automatically use new credentials on next run

### Modifying Update Frequency

Edit `cloudflare-ddns.timer` and change `OnUnitActiveSec=` value:
```bash
sudo systemctl edit cloudflare-ddns.timer
sudo systemctl daemon-reload
sudo systemctl restart cloudflare-ddns.timer
```

### Only Update IPv4
You may wish to only expose/update your IPv4 address. In this case, you just have to delete the second function call in the main `cloudflare-ddns` script.
```diff
-update_dns_record 'v4' "$CF_RECORD_ID_4"
update_dns_record 'v6' "$CF_RECORD_ID_6"
```

## References

- [systemd.exec - LoadCredentialEncrypted](https://www.freedesktop.org/software/systemd/man/systemd.exec.html#LoadCredentialEncrypted=ID:PATH)
- [systemd-creds (freedesktop.org)](https://www.freedesktop.org/software/systemd/man/systemd-creds.html)
- [systemd-creds (systemd.io)](https://systemd.io/CREDENTIALS/)
- [Cloudflare DNS API](https://developers.cloudflare.com/api/operations/dns-records-for-a-zone-patch-dns-record)
- [Helpful blog post](https://congrong.wang/blog/setting-up-dynamic-dns-through-cloudflare/)
