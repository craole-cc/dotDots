{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    dosfstools
    zfstools
    exfat
    # exfatprogs
    btrfs-progs
    btrfs-snap
    btrfs-heatmap
    ntfs3g
    gparted
  ];
}
