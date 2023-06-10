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

- [ ] Initialize the DOTS

  ```sh
  #@ Define dotfiles directory
  DOTS="$HOME/DOTS"

  #@ Define the scripts directory
  NIXS="$DOTS/Scripts"

  #@ Make the scripts available
  PATH="$PATH:$NIXS"

  #@ Export environment variables
  export DOTS NIXS PATH
  ```

- [ ] Define handy functions for interacting with the dotfiles:

  ```sh
  dots_init(){
    #@ Delete the dotfiles
    rm -rf "$DOTS"

    #@ Clone the dotfiles repository
    git clone https://github.com/craole-cc/dotfiles.git "$DOTS"

    #@ Make scripts executable
    find "${DOTS}/Scripts" \
        -type f ! \
        -perm -u=x \
        -exec chmod u+x {} \;
  }

  dots_update() {
    pushd "$DOTS" &&
    git pull &&
    popd
  }

  dots_edit() {
    hx $"$DOTS"/nixOSzfs
  }

  dots_run() {
    sh DOTS/Scripts/nixOSzfs
  }
  ```
