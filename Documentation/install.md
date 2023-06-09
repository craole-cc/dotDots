# Install

## Boot

```sh
sudo -i
setfont ter-v32n
```

## Wi-Fi

```sh
systemctl start wpa_supplicant
INTERFACE="wlp4s0"
SSID="ARRIS-7D7B-5G"
SSID_KEY="50A5DC337d7B"
wpa_supplicant -B -i "$INTERFACE" -c <(wpa_passphrase "$SSID" "$SSID_KEY")
```

```sh
wpa_cli
add_network
set_network 0 ssid "ARRIS-7D7B-5G"
set_network 0 password "50A5DC337d7b"
set_network 0 key_mgmt WPA-PSK
enable_network 0
quit
```

```sh
passwd
systemctl restart dhcp
ip -a
```

## Script

```sh
nix-shell --packages git
```

```sh
git clone https://github.com/craole-cc/dotfiles.git
chmod +x ./dotfiles/Scripts/NixOS_on_ZFS
./dotfiles/Scripts/NixOS_on_ZFS
```

```sh
pushd dotfiles/ && git pull && popd && . dotfiles/Scripts/NixOS_on_ZFS
```