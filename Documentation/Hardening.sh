#!/bin/sh

: <<'DOCUMENTATION'
  Initialization of a new remote server. Brackets are used to allow inserting blocks of code to the terminal.
DOCUMENTATION

## Access Host from Local Machine
: <<'LOCAL_sh'
  {
    # |> Establish variables <|
    _USER_="root"
    _HOST_="161.97.150.15"
    _port="22"

    # |> Login via SSH <|
    ssh $_USER_@$_HOST_ -p $_port
  }
LOCAL_sh

{
  echo "connected"
}

## Backup Files
  {
    export TIME=$(date --utc +"%Y%m%dT%H%M%S_%Z")
    export ARCHIVE="$HOME/.archive"

    cp() {
      cp \
        --parents \
        --backup \
        --suffix=$TIME \
        --target-directory=$ARCHIVE \
        --preserve=all \
        --verbose \
        $*
    }

    touch testcopy
    cp testcopy

    _DATE_=$(date --utc  +"%Y%m%dT%H%M%S_%Z")
    _FILE_="$HOME/.bashrc"
    [ -f "$_FILE_" ] &&
      cp "$_FILE_" "$_ARCHIVE_"

    _FILE_=/etc/ssh/sshd_config
    [ -f "$_FILE_" ] &&
      cp "$_FILE_" "$_FILE_"_"$_DATE_"
  }


## Display OS Information
{
  _FILE_=~/.shell/test.sh
  cat <<- 'shellscript' | tee --append "$_FILE_"

  #!/bin/sh
  # |> OS Information <|
    # *** Name & Version *** #
    OS_Info() {
      if [ -f /etc/os-release ]; then
        # freedesktop.org and systemd
        . /etc/os-release
        OS_NAME=$NAME
        OS_VERSION=$VERSION_ID
      elif type lsb_release >/dev/null 2>&1; then
        # linuxbase.org
        OS_NAME=$(lsb_release -si)
        OS_VERSION=$(lsb_release -sr)
      elif [ -f /etc/lsb-release ]; then
        # For some versions of Debian/Ubuntu without lsb_release command
        . /etc/lsb-release
        OS_NAME=$DISTRIB_ID
        OS_VERSION=$DISTRIB_RELEASE
      elif [ -f /etc/debian_version ]; then
        # Older Debian/Ubuntu/etc.
        OS_NAME=Debian
        OS_VERSION=$(cat /etc/debian_version)
      elif [ -f /etc/SuSe-release ]; then
        # Older SuSE/etc.
        ...
      elif [ -f /etc/redhat-release ]; then
        # Older Red Hat, CentOS_NAME, etc.
        ...
      else
        # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
        OS_NAME=$(uname -s)
        OS_VERSION=$(uname -r)
      fi
    # *** Architecture *** #
    {
      case $(uname -m) in
        x86_64)
            OS_ARCH=x64  # or AMD64 or Intel64 or whatever
            ;;
        i*86)
            OS_ARCH=x86  # or IA32 or Intel32 or whatever
            ;;
        *)
            # leave OS_ARCH as-is
            ;;
        esac
    }
    # *** Label *** #
    OS_LABEL="$OS_NAME $OS_VERSION $OS_ARCH"

    export OS_LABEL \
    OS_NAME \
    OS_VERSION \
    OS_ARCH
shellscript
bat "$_FILE_"
# bash
# echo "$OS_LABEL"
}

## Update Packages & Prompt
  {
    # |> Install Updates <|
      if
        echo "$OS_NAME $OS_VERSION x$BITS" | grep -q "Ubuntu" ;then
        # shellcheck disable=SC2117
        su -
        apt update
        apt -y full-upgrade
        apt -y autoremove
      elif
        echo "$OS_NAME $OS_VERSION x$BITS" | grep -q "Arch" ;then
        sudo pacman \
          --sync \
          --refresh \
          --sysupgrade \
          --noconfirm \
          --quiet
      fi
    # |> Install Packages <|
      # Starship Prompt
      sh -c "$(curl -fsSL https://starship.rs/install.sh)"
      sh -c "$(curl https://raw.githubusercontent.com/anhsirk0/fetch-master-6000/master/install.sh)" > "$HOME/.config/fm6000"
  }

## Establish GateKeeper
  {
    adduser gatekeeper
  }




    Install Dependencies



    apt install exa

  }
