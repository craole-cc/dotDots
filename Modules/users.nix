{
  host,
  inputs,
  lib,
  lix,
  pkgs,
  ...
}: let
  inherit (lib.attrsets) filterAttrs mapAttrs optionalAttrs;
  inherit (lib.lists) elem head optionals;
  inherit (lib.modules) mkDefault;
  inherit (lix.configuration.core) mkSudoRules;
  inherit (lix.attrsets.resolution) package;

  users = host.users.data.enabled or {};
  names = host.users.names.enabled or [];
  admins = host.users.names.elevated or [];

  #> Collect all enabled regular users (non-service, non-guest)
  normalUsers = filterAttrs (_: u: !(elem u.role ["service" "guest"])) users;

  perUser =
    mapAttrs (name: cfg: let
      isNormalUser = cfg.role != "service";
    in {
      coreUser = {
        inherit isNormalUser;
        isSystemUser = !isNormalUser;
        description = cfg.description or name;

        #> Use first shell as default
        shell = package {
          inherit pkgs;
          target = head (cfg.shells or ["bash"]);
        };

        password = cfg.password or null;
        group = name;
        extraGroups =
          []
          ++ optionals
          (!elem (cfg.role or null) ["service"])
          ["users"]
          ++ optionals
          (elem (cfg.role or null) ["admin" "administrator"])
          ["wheel"]
          ++ optionals
          (isNormalUser && (host.devices.network or []) != [])
          ["networkmanager"];
      };

      homeUser = {
        _module.args.user = cfg // {inherit name;};
        home = {
          inherit (host) stateVersion;
          packages = with pkgs; (map (shell:
            package {
              inherit pkgs;
              target = shell;
            })
          cfg.shells);
        };
        programs = {
          home-manager.enable = true;
          bash.enable = mkDefault (elem "bash" (cfg.shells or []));
          zsh.enable = mkDefault (elem "zsh" (cfg.shells or []));
          fish.enable = mkDefault (elem "fish" (cfg.shells or []));
          nushell.enable = mkDefault (elem "nushell" (cfg.shells or []));
        };
        wayland.windowManager.hyprland.enable = cfg.interface.windowManager or null == "hyprland";
      };
    })
    users;
in {
  imports = [inputs.modules.core.home-manager];
  security.sudo = {
    #> Restrict sudo to members of the wheel group (root is always allowed).
    execWheelOnly = true;

    #> For each admin user, grant passwordless sudo for all commands.
    extraRules = mkSudoRules admins;
  };

  users.users = mapAttrs (_name: cfg: cfg.coreUser) perUser;

  home-manager = {
    backupFileExtension = "BaC";
    overwriteBackup = true;
    useGlobalPkgs = true;
    useUserPackages = true;
    # extraSpecialArgs =
    #   specialArgs
    #   // {
    #     inherit users;
    #     inherit (pkgs.stdenv.hostPlatform) system;
    #   };

    #> Merge all per-user home-manager configs
    users = mapAttrs (_name: cfg: cfg.homeUser) perUser;
  };
}
