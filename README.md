# discord-deb2arch

Converts Discord's official `.deb` release into a native Arch package using debtap. The community repo tends to lag behind official releases, so this handles the fetch and install automatically.

This repository serves two purposes:

- **AUR package** (`PKGBUILD`) — installs Discord directly by extracting the official `.deb`. It provides and conflicts with `discord`, so it replaces the community repo package cleanly.
- **Maintainer script** (`discord-update.sh`) — detects new Discord releases, updates the PKGBUILD and `.SRCINFO`, and pushes the change to AUR automatically.

## Installing Discord

```bash
yay -S discord-deb2arch
```

This replaces the `discord` package from the community repo with the latest upstream release.

## Maintainer usage

The update script is for keeping the AUR package up-to-date when Discord releases a new version.

```
./discord-update.sh [OPTIONS]

  -f, --force      Update even if already on the latest version
  -d, --dry-run    Show what would change without writing anything
  -h, --help       Show this help and exit
```

```bash
# Check for a new release and push to AUR if found
./discord-update.sh

# Preview what would change without writing anything
./discord-update.sh --dry-run
```

### First-time AUR setup

Clone the AUR remote into this repo:

```bash
git remote add aur ssh://aur@aur.archlinux.org/discord-deb2arch.git
```

Then generate the initial `.SRCINFO` and push:

```bash
makepkg --printsrcinfo > .SRCINFO
git add PKGBUILD .SRCINFO
git commit -m "initial release"
git push aur main
```

After that, running `./discord-update.sh` handles everything on its own.

## Automate with systemd

Run the updater daily so the AUR package stays current without manual effort.

```bash
mkdir -p ~/.config/systemd/user

cat > ~/.config/systemd/user/discord-deb2arch.service <<'EOF'
[Unit]
Description=discord-deb2arch AUR updater
After=network-online.target

[Service]
Type=oneshot
ExecStart=/path/to/discord-update.sh
StandardOutput=journal
StandardError=journal
EOF

cat > ~/.config/systemd/user/discord-deb2arch.timer <<'EOF'
[Unit]
Description=Run discord-deb2arch updater daily

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now discord-deb2arch.timer
```

## License

MIT
