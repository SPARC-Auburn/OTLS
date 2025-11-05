OTSL Add-ons (alerts, remote access, sync, comparison)
=====================================================
Files:
- otls_healthcheck.sh      Enhanced watchdog with email/webhook alerts
- daily_selfcheck.sh       24h summary report (cron daily)
- otls_defaults.example    /etc/default/otls template (env for scripts)
- sync_to_vm.sh            rsync logs to your DigitalOcean VM
- compare_otls.py          Compare two CSVs and summarize drift/B/pressure
- setup_hostname.sh        Set static hostname + enable .local via Avahi
- install_tailscale.sh     Install Tailscale (secure remote access)

Cron examples:
*/15 * * * * /usr/local/bin/otls_healthcheck.sh
0 7 * * *   /usr/local/bin/daily_selfcheck.sh

Sync to VM (hourly):
0 * * * * /usr/local/bin/sync_to_vm.sh