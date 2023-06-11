# nixOSzfs

## Font

> Make the font bigger, if necessary

```sh
setfont ter-v32n
```

## Elevated shell

> Become the root user

```sh
 sudo -i
```

> Set the root user password

```sh
passwd
```

## Network Connection

### Ethernet

> Restart the dhcp server to allow ssh access

  ```sh
  systemctl restart dhcp
  ```

### WIFI

> Define the network info for the Wi-Fi connection

  ```sh
  # Network interface (Use 'ip a')
  interface="wlp4s0"

  # SSID (network name) of the Wi-Fi network
  ssid="ARRIS-7D7B-5G"

  # Password for the Wi-Fi network
  ssid_key="50A5DC337D7B"

  # Path to the wpa_supplicant configuration file
  wpa_conf="/etc/wpa_supplicant.conf"
  ```

> Connect to the WiFi network

  ```sh
  wpa_passphrase "$ssid" "$ssid_key" > "$wpa_conf"
  wpa_supplicant -B -i "$interface" -c "$wpa_conf"
  systemctl start wpa_supplicant.service
  ```

### Verify the connection

  > Network Info

  ```sh
  iwconfig
  ```

  > IP Address

  ```sh
  ip a | grep 192
  ```

> Connect from another system via ssh

```sh
# ssh root@<ipaddress>
ssh root@192.168.0.11
```

## Dotfiles

> Define the core environment

  ```sh
  #@ Define the temporary mountpoint
  MNT="$(mktemp -d)"

  #@ Define dotfiles directory
  DOTS="$MNT/etc/nixos"
  mkdir --parents "$DOTS"

  #@ Define the scripts directory
  NIXS="$DOTS/Scripts"

  #@ Make the scripts available
  PATH="$PATH:$NIXS"

  #@ Export core environment variables
  export MNT DOTS NIXS MNT PATH
  ```

> Get the dotfiles

```sh
#@ Install git
nix-env -f '<nixpkgs>' -iA git

#@ Clone the dotfiles repository
git clone https://github.com/craole-cc/dotfiles.git "$DOTS"

#@ Exit the temporary shell
chmod u+x $NIXS/get_updated_dots
sh $NIXS/get_updated_dots
```

> Get the disk information

```sh
#@ Identify the disks
lsblk

#@ Find the Disk ID(s) [eg. nvme0n1]
get_disk_id nvme0n1
```

> Define the installer environment

```sh
#@ Define the disks (separated by space)
disk_array="/dev/disk/by-id/nvme-HFM256GDJTNG-8310A_CY9CN00281150CJ46"

#@ Define the git informantion
git_email="craole-cc@proton.me"
git_user="craole-cc"

#@ Export installer environment variables
export disk_array git_email git_user temp_mnt
```
