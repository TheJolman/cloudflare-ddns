script_src = cloudflare-ddns
service_src = cloudflare-ddns.service
timer_src = cloudflare-ddns.timer

bin_dest = /usr/local/bin/
systemd_dest = /etc/systemd/system/
secret_dest = /etc/cloudflare-ddns/

.PHONY: all set-secrets install uninstall format lint

all:
	@echo "Usage: sudo make [ set-secrets | install | uninstall ]"

set-secrets:
	@./secret_helper.sh CF_ZONE_ID
	@./secret_helper.sh CF_RECORD_ID_4
	@./secret_helper.sh CF_RECORD_ID_6
	@./secret_helper.sh CF_API_TOKEN
	@./secret_helper.sh IPINFO_API_TOKEN

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

format:
	shfmt -w --indent 2 -ci cloudflare-ddns

lint:
	shellcheck cloudflare-ddns
