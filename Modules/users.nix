{
  host,
  inputs,
  lib,
  lix,
  pkgs,
  src,
  ...
}: let
  inherit (lib.attrsets) attrValues filterAttrs mapAttrs optionalAttrs attrByPath;
  inherit (lib.lists) any concatMap elem head optionals;
  inherit (lib.modules) mkDefault;
  inherit (lix.modules.core) mkSudoRules;
  inherit (lix.attrsets.resolution) package;
  inherit (lix.applications.firefox) zenVariant;
  inherit (lix.lists.predicates) isIn;

  users = host.users.data.enabled or {};
  names = host.users.names.enabled or [];
  admins = host.users.names.elevated or [];
  zen = cfg: zenVariant (attrByPath ["applications" "browser" "firefox"] null cfg);

  # Check if any user needs nvf
  allEditors = concatMap (u:
    [
      (u.applications.editor.tty.primary or "")
      (u.applications.editor.tty.secondary or "")
    ]
    ++ (u.applications.allowed or [])) (attrValues users);
  needNvf = isIn ["neovim" "nvim" "nvf" "vim"] allEditors;
  needPlasma = any (u: u.interface.desktopEnvironment or null == "plasma") (attrValues users);
  needNoctalia = any (u: u.interface.bar or null == "noctalia") (attrValues users);
  needDms = any (u: u.interface.bar or null == "dms") (attrValues users);

  mods = inputs.modules or {};

  #> Collect all enabled regular users (non-service, non-guest)
  normalUsers = filterAttrs (_: u: !(elem u.role ["service" "guest"])) users;
in {
  imports = with inputs.modules.core; [home-manager];

  users.users =
    mapAttrs (name: cfg: {config, ...}: {
      isNormalUser = cfg.role != "service";
      isSystemUser = cfg.role == "service";
      description = cfg.description or name;

      shell = package {
        inherit pkgs;
        target = head (cfg.shells or ["bash"]);
      };

      password = cfg.password or null;
      group = name;
      extraGroups =
        []
        ++ optionals (!elem (cfg.role or null) ["service"]) ["users"]
        ++ optionals (elem (cfg.role or null) ["admin" "administrator"]) ["wheel"]
        ++ optionals (host.devices.network != []) ["networkmanager"]
        ++ [];
    })
    users;

  home-manager = {
    backupFileExtension = "BaC";
    overwriteBackup = true;
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit (pkgs.stdenv.hostPlatform) system;
      inherit lix host;
    };

    #> Merge all per-user home-manager configs
    users =
      mapAttrs (name: cfg: {
        _module.args.user = cfg // {inherit name;};
        imports =
          (with inputs.modules.home; [
            nvf
            noctalia-shell
            dank-material-shell
            plasma
            zen-browser
          ])
          ++ cfg.imports or []
          ++ [../Packages/home];
      })
      (filterAttrs (_: u: (!elem u.role ["service" "guest"])) users);
  };

  security.sudo = {
    #> Restrict sudo to members of the wheel group (root is always allowed).
    execWheelOnly = true;

    #> For each admin user, grant passwordless sudo for all commands.
    extraRules = mkSudoRules admins;
  };
}
