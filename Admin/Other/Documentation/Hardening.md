# Hardening the Server

## Access via Local Machine

```sh
{
  _user=root
  _host=161.97.150.15
  _port=22
  ssh $_user@$_host -p $_port
}
```

## Update Packages

```sh
  {
    # |> Label OS & Version <|
      if [ -f /etc/os-release ]; then
        # freedesktop.org and systemd
        . /etc/os-release
        OSname=$NAME
        OSversion=$VERSION_ID
      elif type lsb_release >/dev/null 2>&1; then
        # linuxbase.org
        OSname=$(lsb_release -si)
        OSversion=$(lsb_release -sr)
      elif [ -f /etc/lsb-release ]; then
        # For some versions of Debian/Ubuntu without lsb_release command
        . /etc/lsb-release
        OSname=$DISTRIB_ID
        OSversion=$DISTRIB_RELEASE
      elif [ -f /etc/debian_version ]; then
        # Older Debian/Ubuntu/etc.
        OSname=Debian
        OSversion=$(cat /etc/debian_version)
      elif [ -f /etc/SuSe-release ]; then
        # Older SuSE/etc.
        ...
      elif [ -f /etc/redhat-release ]; then
        # Older Red Hat, CentOSname, etc.
        ...
      else
        # Fall back to uname
        OSname=$(uname -s)
        OSversion=$(uname -r)
      fi
      case $(uname -m) in
        x86_64)
            ARCH=x64  # or AMD64 or Intel64 or whatever
            ;;
        i*86)
            ARCH=x86  # or IA32 or Intel32 or whatever
            ;;
        *)
            # leave ARCH as-is
            ;;
        esac

    # Update
      if echo "$OSname $OSversion x$BITS" | grep -q "Ubuntu" ;then
        sudo apt update
        sudo apt -y full-upgrade
        sudo apt -y autoremove

      fi
      if echo "$OSname $OSversion x$BITS" | grep -q "Arch" ;then
        sudo pacman --sync --upgrade --noconfirm
      fi
  }
```

## Create Limited User

---

This profile is to facilitate login independent of root.

```sh
$_file=~/.test
$_date=$(date --utc  +"%Y%m%dT%H%M%S")
# cp $_file $_file_"$(whoami)$(uname -n)_$(date -I)".bak $(date --utc  +"%Y%m%dT%H%M%S")
echo $_file
{
  # adduser gatekeeper
  # su -gatekeeper
  cat <<EOF | tee --append ~/.test
  # Become Root
  su -
  EOF
  bash
}
```

## SSHD

---
Restrict SSH access to encrypted key login

```sh
{
# |> Authorize local machine

  # |> Establish variables <|
    _user="gatekeeper"
    _host=161.97.150.15
    _dir=~/.ssh/contabo/
    _key="vps1"

  # |> Confirm directory exist <|
    [ ! -d $_dir ] &&
      mkdir -p "$_dir" &&
        _key=$_dir/$_key
    echo $_key

  # |> Create key pair <|
  # See: https://man.openbsd.org/cgi-bin/man.cgi/OpenBSD-current/man1/ssh-keygen.1?query=ssh-keygen&sec=1
      ssh-keygen \
        -C "$(whoami)$(uname -n)_$(date -I)" \
        -f $_key \
        -t ed25519 \
        -a 100 \
        -N ""

  # |> Update Host <|
    ssh-copy-id -i "$_key.pub" "$_user"@"$_host"

  # |> Test Access <|
    ssh "$_user"@"$_host" -i "$_key"
}
```

```sh
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
cat <<EOF | tee /etc/ssh/sshd_config
#       $OpenBSD: sshd_config,v 1.103 2018/04/09 20:41:22 tj Exp $

# This is the sshd server system-wide configuration file. See
# sshd_config(5) for more information.

# |> Modules <|
Include /etc/ssh/sshd_config.d/*.conf

# |> Authentication <|
Port 876
PermitRootLogin no
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM no

# |> Additional Settings <|
X11Forwarding no
PrintMotd no
ClientAliveInterval 300
AcceptEnv LANG LC_*
Subsystem       sftp    /usr/lib/openssh/sftp-server
EOF
systemctl restart sshd
 ```


## UFW

---

```sh
sudo pacman -Syu ufw;
sudo systemctl enable ufw;
 ```

## Fail2Ban

---

### Install & Enable

```sh
sudo pacman -Syu fail2ban;
sudo systemctl enable fail2ban;
sudo systemctl start fail2ban;
sudo systemctl status fail2ban
 ```

### Configure for SSH

> *`sshd.local`*

 ```sh
 sudo vim /etc/fail2ban/jail.d/sshd.local
 ```

```sh
[sshd]
enabled   = true
filter    = sshd
banaction = ufw
backend   = systemd
maxretry  = 3
findtime  = 1d
bantime   = 2w
# ignoreip  = 127.0.0.1/8
```

### Refresh

 ```bash
sudo systemctl daemon-reload
sudo systemctl restart fail2ban;
```
