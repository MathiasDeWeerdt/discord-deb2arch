# discord-deb2arch

Converts Discord's official `.deb` release into a native Arch package using debtap. The community repo tends to lag behind official releases, so this handles the fetch and install automatically.

```
discord CDN (.deb)  →  debtap  →  .pkg.tar.zst  →  pacman
```

Version detection reads the `302 Location` redirect header, so the full package is only downloaded when an update is actually available.

## Dependencies

| Tool | Install |
|------|---------|
| `wget` | `sudo pacman -S wget` |
| `debtap` | `yay -S debtap` |

On first use, initialise the debtap package database:
```bash
sudo debtap -u
```

## Installation

```bash
git clone https://github.com/YOUR_USERNAME/discord-deb2arch
cd discord-deb2arch
sudo cp discord-update.sh /usr/local/bin/discord-update
```

## Usage

```
discord-update [OPTIONS]

  -f, --force        Skip version check and reinstall
  -u, --update-db    Refresh the debtap package database first
  -h, --help         Show this help and exit
```

```bash
# Check for an update and install if available
discord-update

# Refresh the debtap DB and update
discord-update --update-db

# Reinstall the current latest version
discord-update --force
```

## Automate with systemd

Run the updater daily without lifting a finger.

```bash
mkdir -p ~/.config/systemd/user

cat > ~/.config/systemd/user/discord-update.service <<'EOF'
[Unit]
Description=discord-deb2arch updater
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/discord-update --update-db
StandardOutput=journal
StandardError=journal
EOF

cat > ~/.config/systemd/user/discord-update.timer <<'EOF'
[Unit]
Description=Run discord-deb2arch daily

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now discord-update.timer
```

Check status:
```bash
systemctl --user status discord-update.timer
journalctl --user -u discord-update.service
```

## License

MIT
