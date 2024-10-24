{ lib, pkgs, config, modulesPath, ...}:
with lib; let
  nixos-wsl = import ./nixos-wsl;
in {
  imports = [
    "\${modulesPath}/profiles/minimal.nix"
    nixos-wsl.nixosModules.wsl
    <home-manager/nixos>
    \$NixWSL_conf
  ];

  wsl = {
    enable = true;
    automountPath = "/mnt";
    defaultUser = "\$NixWSL_user";
    startMenuLaunchers = true;
  };

  system = {
    autoUpgrade = {
      enable = lib.mkDefault true;
      allowReboot = lib.mkDefault true;
    };
    stateVersion = lib.mkDefault "$NixWSL_vr3n";
  };

  environment = {
    shellAliases = {
      NixOS-WSL = "cd $wsl_conf && sh init";
      fmt_wsl_conf = "alejandra format $wsl_conf --quiet --exclude $wsl_conf/archive;

      # Nix Channel
      channix-nixos = "sudo nix-channel --add https://channels.nixos.org/nixos-${NixWSL_vr3n} nixos";
      channix-home = "sudo nix-channel --add https://github.com/nix-community/home-manager/archive/release-${NixWSL_vr3n}.tar.gz home-manager";
      channix-unstable = "sudo nix-channel --add https://channels.nixos.org/nixos-unstable nixos-unstable";
      channix-list = "sudo nix-channel --list";
      channix-update = "sudo nix-channel --update";
    };
  };
}