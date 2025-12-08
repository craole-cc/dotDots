{ args }:
let
  inherit (args) pkgs lib;
  inherit (lib.options) mkOption mkEnableOption literalExample;
  inherit (lib.types) submodule;
in
mkOption {
  description = "NixOS system-level configuration options (versioning, channel)";
  default = { };
  type = submodule {
    options = {
      allowUnfree = mkEnableOption "unfree packages" // {
        default = true;
      };

      allowUnstable = mkEnableOption "unstabe NixOS repository" // {
        default = true;
      };

      allowSmall = mkEnableOption "small branch of the NixOS repository";

      kernel = mkOption {
        description = ''
          Specifies the Linux kernel package to use for this host.
          Accepts either a package or a string referring to a kernel version.
          If unset, the latest Linux kernel package will be used.

          Reference: https://nixos.org/manual/nixos/unstable/index.html#sec-kernel-config
        '';
        example = literalExample ''
          pkgs.linuxPackages_latest
          # or
          "linuxPackages_latest"
        '';
        default = pkgs.linuxPackages_latest;
        # type = nullOr (either package str);
      };
    };
  };
}
