#? Hardware description for this host.
#?
#? `hardware-configuration.nix` is the generated file: it carries the disk UUIDs,
#? filesystem subvolumes and initrd kernel modules that `nixos-generate-config`
#? wrote for this machine. It is imported unconditionally rather than being
#? merged into a hand-written module, because the values are facts about the
#? disk -- editing them by hand is how a host ends up unbootable.
#?
#? Omitting it drops `fileSystems`, and the build fails the assertion that a root
#? file system must be declared.
{
  imports = [
    ./hardware-configuration.nix
    ./bluetooth.nix
  ];
}
