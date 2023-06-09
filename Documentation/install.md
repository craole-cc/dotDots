# Install

## Boot

```sh
sudo -i
setfont ter-v32n
```

## Wi-Fi

```sh
passwd
systemctl start wpa_supplicant.service
INTERFACE="wlp4s0"
SSID="ARRIS-7D7B-5G"
SSID_KEY="50A5DC337D7B"
wpa_supplicant -B -i "$INTERFACE" -c <(wpa_passphrase "$SSID" "$SSID_KEY")
ip -a | grep 192
```

## Script

```sh
# nix-shell --packages git
nix-env -f '<nixpkgs>' -iA  git
git clone https://github.com/craole-cc/dotfiles.git
chmod +x ./dotfiles/Scripts/NixOS_on_ZFS
pushd dotfiles/ && git pull && popd && . dotfiles/Scripts/NixOS_on_ZFS
```
