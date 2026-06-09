# Victus Setup Notes

## Monitors

Find monitor info:

```sh
hyprctl monitors
```

Find current monitor config:

```sh
grep -r "monitor" ~/.config/hypr/hyprland.conf
```

<!-- Edit `~/.config/hypr/hyprland.conf` — replace the monitor lines with: -->

<!-- ```txt -->
<!-- monitor=DP-3, 1600x900@60, 480x0, 1 -->
<!-- monitor=HDMI-A-2, 2560x1440@60, 0x900, 1 -->
<!-- ``` -->

- `DP-3` = Dell (1600x900) — positioned above, centered over the HTC
- `HDMI-A-2` = HTC (2560x1440) — base monitor

Apply changes:

```sh
sed -i \
  -e 's|monitor=HDMI-A-3.*|monitor=HDMI-A-2, 2560x1440@60, 0x900, 1|' \
  -e 's|monitor=DP-3.*|monitor=DP-3, 1600x900@60, 480x0, 1|' \
  ~/.config/hypr/hyprland.conf && hyprctl reload
hyprctl reload
```

---

## Tailscale (temporary — until NixOS config is fixed)

Install via nix profile:

```sh
nix profile install nixpkgs#tailscale
```

Start daemon and connect:

```sh
sudo tailscaled --state=/var/lib/tailscale/tailscaled.state > /tmp/tailscaled.log 2>&1 &&
sudo tailscale up && tailscale status
```

Visit the auth URL printed in the terminal, then check status:

```sh
tailscale status
```

> **Note:** Re-run the `tailscaled` line after each reboot until Tailscale is properly wired into your NixOS config.

---

## SSH (passwordless into Preci)

One-time setup from Victus:

```sh
ssh-keygen -t ed25519   # skip if key already exists
ssh-copy-id craole@preci
```

Connect:

```sh
ssh craole@preci
```

Tailscale hostnames (from `tailscale status`):

| Hostname     | IP              | OS      |
|--------------|-----------------|---------|
| preci        | 100.68.57.127   | linux   |
| victus       | 100.90.252.109  | linux   |
| dbook        | 100.75.7.128    | linux   |
| qbx-nixos    | 100.94.220.55   | linux   |
| victus-win   | 100.102.11.27   | windows |
| qbx-win11    | 100.97.229.52   | windows |
