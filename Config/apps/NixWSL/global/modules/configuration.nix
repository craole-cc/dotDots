{ lib, pkgs, config, modulesPath, ... }:

let
  nixos-wsl = import ./nixos-wsl;

  # Read the variables from /etc/bashrc.local
  bashrc = builtins.readFile "/etc/bashrc.local";
  vars = lib.filterAttrs (key: _value: key != "") (lib.attrValues (builtins.parseDrvName bashrc));

  NixWSL_conf = vars.NixWSL_conf or "";
  NixWSL_user = vars.NixWSL_user or "";
  NixWSL_vr3n = vars.NixWSL_vr3n or "";
in
{
  imports =
    [ "${modulesPath}/profiles/minimal.nix"
      nixos-wsl.nixosModules.wsl
      <home-manager/nixos>
      NixWSL_conf
    ];

  wsl = {
    enable = true;
    automountPath = "/mnt";
    defaultUser = NixWSL_user;
    startMenuLaunchers = true;
  };

  system = {
    autoUpgrade = {
      enable = lib.mkDefault true;
      allowReboot = lib.mkDefault true;
    };
    stateVersion = lib.mkDefault NixWSL_vr3n;
  };

  environment = {
    shellAliases = {
      NixOS-WSL = "cd $NixWSL_conf && sh init";
      fmt_wsl_conf = "alejandra format $NixWSL_conf --quiet --exclude $NixWSL_conf/archive";

      # Nix Channel
      channix-nixos = "sudo nix-channel --add https://channels.nixos.org/nixos-$NixWSL_vr3n nixos";
      channix-home = "sudo nix-channel --add https://github.com/nix-community/home-manager/archive/release-$NixWSL_vr3n.tar.gz home-manager";
      channix-unstable = "sudo nix-channel --add https://channels.nixos.org/nixos-unstable nixos-unstable";
      channix-list = "sudo nix-channel --list";
      channix-update = "sudo nix-channel --update";
    };
  };
}
