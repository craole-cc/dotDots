# nixOSzfs

- [ ] Switch to an elevated shell

  ```sh
  #@ Switch to root user
  sudo -i

  #@ Set the password to allow connection via ssh
  passwd

  #@ Make the font bigger, if necessary
  setfont ter-v32n
  ```

- [ ] Configure the network

  ```sh
  #@ Enable WiFi, if necessary
  systemctl start wpa_supplicant.service

  #@ Set environment variables
  INTERFACE="wlp4s0"
  SSID="ARRIS-7D7B-5G"
  SSID_KEY="50A5DC337D7B"

  #@ Start the service with the configuration
  wpa_supplicant -B -i "$INTERFACE" -c "$(
    wpa_passphrase "$SSID" "$SSID_KEY"
  )"

  #@ Restart the dhcp server if using wired connection
  systemctl restart dhcp

  #@ Verify the IP address
  ip -a | grep 192
  ```

- [ ] Clone the DOTS

  ```sh
  #@ Install git and helix editor
  nix-env -f '<nixpkgs>' -iA git helix

  #@ Clone the dotfiles repository
  git clone https://github.com/craole-cc/dotfiles.git
  ```

- [ ] Define handy functions for updating the dotfiles:

  ```sh
  dots_pull() {
    pushd dotfiles/ &&
    git pull &&
    popd
  }

  dots_init() {
    chmod --changes +x ./dotfiles/Scripts/nixOSzfs
    sh dotfiles/Scripts/nixOSzfs
  }

  dots_edit() {
    hx dotfiles/Scripts/nixOSzfs
  }
  ```
