script_src = cloudflare-ddns
service_src = cloudflare-ddns.service
timer_src = cloudflare-ddns.timer

bin_dest = /usr/local/bin/
systemd_dest = /etc/systemd/system/
secret_dest = /etc/cloudflare-ddns/

.PHONY: install uninstall

all:
	@echo "Usage: sudo make [ set-secrets | install | uninstall ]"

set-secrets:
	@echo -n "Enter the value for CF_ZONE_ID: "
	@read CF_ZONE_ID; \
	echo -n "$$CF_ZONE_ID" | systemd-creds encrypt --name=CF_ZONE_ID - CF_ZONE_ID

	@echo -n "Enter the value for CF_RECORD_ID_4: "
	@read CF_RECORD_ID_4; \
	echo -n "$$CF_RECORD_ID_4" | systemd-creds encrypt --name=CF_RECORD_ID_4 - CF_RECORD_ID_4

	@echo -n "Enter the value for CF_RECORD_ID_6: "
	@read CF_RECORD_ID_6; \
	echo -n "$$CF_RECORD_ID_6" | systemd-creds encrypt --name=CF_RECORD_ID_6 - CF_RECORD_ID_6

	@echo -n "Enter the value for CF_API_TOKEN: "
	@read CF_API_TOKEN; \
	echo -n "$$CF_API_TOKEN" | systemd-creds encrypt --name=CF_API_TOKEN - CF_API_TOKEN

	@echo -n "Enter the value for IPINFO_API_TOKEN: "
	@read IPINFO_API_TOKEN; \
	echo -n "$$IPINFO_API_TOKEN" | systemd-creds encrypt --name=IPINFO_API_TOKEN - IPINFO_API_TOKEN

	@echo "All secrets encrypted. You can safely delete the local secret files after running 'make install'."


install:
	# Secrets
	install -d -m 700 /etc/cloudflare-ddns
	install -m 600 -o root -g root CF_ZONE_ID $(secret_dest)
	install -m 600 -o root -g root CF_RECORD_ID_4 $(secret_dest)
	install -m 600 -o root -g root CF_RECORD_ID_6 $(secret_dest)
	install -m 600 -o root -g root CF_API_TOKEN $(secret_dest)
	install -m 600 -o root -g root IPINFO_API_TOKEN $(secret_dest)

	# Binary
	install -m 755 -o root -g root $(script_src) $(bin_dest)

	# Systemd units
	install -m 644 -o root -g root $(service_src) $(systemd_dest)
	install -m 644 -o root -g root $(timer_src) $(systemd_dest)

	systemctl daemon-reload
	systemctl enable --now cloudflare-ddns.timer
	@echo "Service installed and started."
	@echo "Run 'sudo journalctl -u cloudflare-ddns.service' to check its status."

uninstall:
	systemctl disable --now $(timer_src) || true

	rm -f $(bin_dest)$(script_src)
	rm -f $(systemd_dest)$(service_src)
	rm -f $(systemd_dest)$(timer_src)
	rm -rf $(secret_dest)

	systemctl daemon-reload
	@echo "Uninstalled and cleaned up."
