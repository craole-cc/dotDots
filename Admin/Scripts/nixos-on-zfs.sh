#!/bin/sh
# shellcheck disable=SC2046,SC2016,SC3045
#DOC https://openzfs.github.io/openzfs-docs/Getting%20Started/NixOS/Root%20on%20ZFS.html
SCR_NAME="$(basename "$0")"
SCR_DESCRIPTION="Install NixOS on a single disk using the ZFS file system for improved performance and memory management."
SCR_DISCLAIMER="DISCLAIMER: This script will delete all data from your disk. Refer to the documentation for more details."

show_usage_guide() {
  cat << EOF
Usage: ${SCR_NAME} [OPTIONS]
Options:
  -d, --disk       DISK      Disk ID (e.g., /dev/disk/by-id/DISK_ID_HERE)
  -e, --git-email  EMAIL     Git email address
  -u, --git-user   USER      Git username
  -s, --swap-size  SIZE      Swap size in GB (default: 4)
  -r, --reserve    SIZE      Reserved space at the end of the disk in GB (default: 1)
  -n, --no-encrypt           Disable encryption (default: enabled)
  -h, --help                 Display this help and exit
Description:
  ${SCR_DESCRIPTION}
Example:
  ${SCR_NAME} -d /dev/disk/by-id/ata-TOSHIBA_MQ01ACF050_76ULCLH7T -e user@example.com -u username -s 4 -r 1
Disclaimer:
  ${SCR_DISCLAIMER}
EOF
}

validate_envirnment() {
  DISK=""
  GIT_EMAIL=""
  GIT_USER=""
  SWAPSIZE=4
  RESERVE=1
  ENCRYPT=false
  MNT=$(mktemp -d)

  while [ "$#" -gt 0 ]; do
    case "$1" in
      -d | --disk)
        if [ -n "${2}" ] && [ -f "$2" ]; then
          DISK="$2"
        else
          pout "Disk ID"
        fi
        ;;
      -e | --email)
        [ -n "${2}" ] && case "${2}" in *@*.*) GIT_EMAIL="$2" ;; *) ;; esac
        [ -n "${GIT_EMAIL}" ] || pout "email address"

        ;;
      -u | --user)
        if [ -n "${2}" ] && [ ${#2} -gt 1 ]; then
          GIT_USER="$2"
        else
          pout "username"
        fi
        ;;
      -s | --swap)
        if [ -n "${2}" ] && [ "${2}" -ge 0 ]; then SWAPSIZE="${2}"; fi
        ;;
      -r | --reserve)
        if [ -n "${2}" ] && [ "${2}" -ge 0 ]; then RESERVE="${2}"; fi
        ;;
      -p | --encrypt) ENCRYPT=true ;;
      -h | --help)
        show_usage_guide
        exit 0
        ;;
      *) pout --option "${1}" ;;
    esac
    shift
  done
}

validate_erasure() {
  printf "%s\n" "${SCR_DISCLAIMER}"
  choice="" && read -r -p "Are you sure you want to continue? [y/N] " choice
  case "${choice}" in
    [Yy]*) printf "%s\n" "Proceeding with prep" ;;
    *)
      printf "%s\n" "Exiting..."
      exit 0
      ;;
  esac
}

validate_dependencies() {
  #{ Install programs needed for system installation
  if ! command -v git; then nix-env -f '<nixpkgs>' -iA git; fi
  if ! command -v jq; then nix-env -f '<nixpkgs>' -iA jq; fi
  if ! command -v helix; then nix-env -f '<nixpkgs>' -iA helix; fi
  if ! command -v partprobe; then nix-env -f '<nixpkgs>' -iA parted; fi
}

create_partitions() {
  parted --script --align=optimal "${DISK}" -- \
    mklabel gpt \
    mkpart EFI 2MiB 1GiB \
    mkpart bpool 1GiB 5GiB \
    mkpart rpool 5GiB -$((SWAPSIZE + RESERVE))GiB \
    mkpart swap -$((SWAPSIZE + RESERVE))GiB -"${RESERVE}"GiB \
    mkpart BIOS 1MiB 2MiB \
    set 1 esp on \
    set 5 bios_grub on \
    set 5 legacy_boot on

  partprobe "${DISK}"
  udevadm settle

  #/> Setup encrypted swap. This is useful if the available memory is small:
  cryptsetup open --type plain --key-file /dev/random "${DISK}"-part4 "${DISK##*/}"-part4
  mkswap /dev/mapper/"${DISK##*/}"-part4
  swapon /dev/mapper/"${DISK##*/}"-part4
}

create_boot_containers() {
  #{ Create a fail-safe boot pool for grub2
  zpool create \
    -o compatibility=grub2 \
    -o ashift=12 \
    -o autotrim=on \
    -O acltype=posixacl \
    -O canmount=off \
    -O compression=lz4 \
    -O devices=off \
    -O normalization=formD \
    -O relatime=on \
    -O xattr=sa \
    -O mountpoint=/boot \
    -R "${MNT}" \
    bpool \
    "$(printf '%s ' "${DISK}-part2")"

  #{ Create root pool for EFI
  zpool create \
    -o ashift=12 \
    -o autotrim=on \
    -R "${MNT}" \
    -O acltype=posixacl \
    -O canmount=off \
    -O compression=zstd \
    -O dnodesize=auto \
    -O normalization=formD \
    -O relatime=on \
    -O xattr=sa \
    -O mountpoint=/ \
    rpool \
    "$(printf '%s ' "${DISK}-part3")"
}

create_sys_container() {
  #/> Create root system container
  if [ "${ENCRYPT}" = true ]; then
    printf "%s\n" "Creating encrypted root pool."
    printf "%s\n%s\n" \
      "WARNING: Please set a strong password and memorize it." \
      "See zfs-change-key(8) for more info"

    #{ Creat and encrypt the root container
    zfs create \
      -o canmount=off \
      -o mountpoint=none \
      -o encryption=on \
      -o keylocation=prompt \
      -o keyformat=passphrase \
      rpool/nixos
  else
    #{ Creat the root container
    zfs create \
      -o canmount=off \
      -o mountpoint=none \
      rpool/nixos
  fi
}

create_datasets() {
  #/> Create system datasets, manage mountpoints with mountpoint=legacy
  zfs create -o mountpoint=legacy rpool/nixos/root
  mount -t zfs rpool/nixos/root "${MNT}"/
  zfs create -o mountpoint=legacy rpool/nixos/home
  mkdir "${MNT}"/home
  mount -t zfs rpool/nixos/home "${MNT}"/home
  zfs create -o mountpoint=legacy rpool/nixos/var
  zfs create -o mountpoint=legacy rpool/nixos/var/lib
  zfs create -o mountpoint=legacy rpool/nixos/var/log
  zfs create -o mountpoint=none bpool/nixos
  zfs create -o mountpoint=legacy bpool/nixos/root
  mkdir "${MNT}"/boot
  mount -t zfs bpool/nixos/root "${MNT}"/boot
  mkdir -p "${MNT}"/var/log
  mkdir -p "${MNT}"/var/lib
  mount -t zfs rpool/nixos/var/lib "${MNT}"/var/lib
  mount -t zfs rpool/nixos/var/log "${MNT}"/var/log
  zfs create -o mountpoint=legacy rpool/nixos/empty
  zfs snapshot rpool/nixos/empty@start
}

init_boot_container() {
  #{ Format and iniyialize the boot partition
  mkfs.vfat -n EFI "${DISK}"-part1
  mkdir -p "${MNT}"/boot/efis/"${DISK##*/}"-part1
  mount -t vfat -o iocharset=iso8859-1 "${DISK}"-part1 "${MNT}"/boot/efis/"${DISK##*/}"-part1
}

init_flake() {
  #{ Enable Nix Flakes functionality
  mkdir -p ~/.config/nix
  printf "%s\n" \
    "experimental-features = nix-command flakes" >> \
    ~/.config/nix/nix.conf

  #{ Clone the template repository
  mkdir -p "${MNT}"/etc
  git clone --depth 1 --branch openzfs-guide \
    https://github.com/ne9z/dotfiles-flake.git "${MNT}"/etc/nixos

  #{ Update the flake with the user's git credentials
  rm -rf "${MNT}"/etc/nixos/.git
  git -C "${MNT}"/etc/nixos/ init -b main
  git -C "${MNT}"/etc/nixos/ add "${MNT}"/etc/nixos/
  git -C "${MNT}"/etc/nixos config user.email "${GIT_EMAIL}"
  git -C "${MNT}"/etc/nixos config user.name "${GIT_USER}"
  git -C "${MNT}"/etc/nixos commit -asm 'initial commit'
}

prep_flake() {
  #{ Prepare configuration based on the system specifications
  sed -i \
    "s|/dev/disk/by-id/|${DISK%/*}/|" \
    "${MNT}"/etc/nixos/hosts/exampleHost/default.nix

  diskNames="" && diskNames="${diskNames} \"${DISK##*/}\""

  sed -i "s|\"bootDevices_placeholder\"|${diskNames}|g" \
    "${MNT}"/etc/nixos/hosts/exampleHost/default.nix

  sed -i "s|\"abcd1234\"|\"$(head -c4 /dev/urandom | od -A none -t x4 | sed 's| ||g' || true)\"|g" \
    "${MNT}"/etc/nixos/hosts/exampleHost/default.nix

  sed -i "s|\"x86_64-linux\"|\"$(uname -m || true)-linux\"|g" \
    "${MNT}"/etc/nixos/flake.nix

  cp "$(command -v nixos-generate-config || true)" ./nixos-generate-config

  chmod a+rw ./nixos-generate-config

  echo 'print STDOUT $initrdAvailableKernelModules' >> ./nixos-generate-config

  kernelModules="$(./nixos-generate-config --show-hardware-config --no-filesystems | tail -n1 || true)"

  sed -i "s|\"kernelModules_placeholder\"|${kernelModules}|g" \
    "${MNT}"/etc/nixos/hosts/exampleHost/default.nix

  sed -i "s|\"swapPartition_placeholder\"|\"${DISK##*/}\"-part4|g" \
    "${MNT}"/etc/nixos/hosts/exampleHost/default.nix

  sed -i "s|\"rootPartition_placeholder\"|\"${DISK##*/}\"-part3|g" \
    "${MNT}"/etc/nixos/hosts/exampleHost/default.nix

  sed -i "s|\"efiPartition_placeholder\"|\"${DISK##*/}\"-part1|g" \
    "${MNT}"/etc/nixos/hosts/exampleHost/default.nix
}

deploy_flake() {
  nixos-enter "${MNT}"/etc/nixos/hosts/exampleHost/ -- \
    nixos-install --flake "${MNT}"/etc/nixos/#

  printf "%s\n" "Installation completed successfully."
}

prevent_reboot() {
  #{ Allow the user some time to cancel the reboot
  timer=10 \
    && printf "Rebooting in %s seconds. Is that OK? [Y/n] \n" "${timer}"
  choice="" \
    && IFS= read -r -t "${timer}" choice

  #{ Exit the script
  case "${choice}" in
    [nN]*) printf "%s\n" "Reboot canceled" ;;
    *) printf "%s\n" "Rebooting..." ;;
  esac
}

pout() {
  #{ Print appropriate error message
  case "${1}" in
    --option)
      shift
      printf "Invalid option: %s\n" "${1}"
      ;;
    *)
      shift
      printf "A valid %s is required \n" "${*}"
      ;;
  esac

  #{ Print usage and exit with an error code
  show_usage_guide
  exit 1
}

main() {
  validate_envirnment "$@"
  validate_erasure
  validate_dependencies
  create_partitions
  create_boot_containers
  create_sys_container
  create_datasets
  init_boot_containers
  init_flake
  prep_flake
  deploy_flake
  prevent_reboot
} && main "$@"
