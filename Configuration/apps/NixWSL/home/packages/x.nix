
    { lib, pkgs, config, modulesPath, ...}:
    with lib; let
      nixos-wsl = import ./nixos-wsl;
    in {
      imports = [
        "\${modulesPath}/profiles/minimal.nix"
        nixos-wsl.nixosModules.wsl
        <home-manager/nixos>
        $wsl_conf
      ];

      wsl = {
        enable = true;
        automountPath = "/mnt";
        defaultUser = "$wsl_user";
        startMenuLaunchers = true;
      };

      system = {
        autoUpgrade = {
          enable = lib.mkDefault true;
          allowReboot = lib.mkDefault true;
        };
        stateVersion = lib.mkDefault $wsl_vr3n;
      };

      environment = {
        shellAliases = {
          NixOS-WSL = "cd $wsl_conf && sh init";
          fmt_wsl_conf = "alejandra format $wsl_conf --quiet --exclude $wsl_conf/archive;

          # Nix Channel
          channix-nixos = "sudo nix-channel --add https://channels.nixos.org/nixos-${wsl_vr3n} nxos";
          channix-home = "sudo nix-channel --add https://github.com/nix-community/home-manager/archive/release-${wsl_vr3n}.tar.gz home-manager";
          channix-unstable = "sudo nix-channel --add https://channels.nixos.org/nixos-unstable nixos-unstable";
          channix-list = "sudo nix-channel --list";
          channix-update = "sudo nix-channel --update";
        };
      };
}