{
  _,
  lib,
  ...
}: let
  inherit (lib.attrsets) attrValues filterAttrs mapAttrs optionalAttrs attrByPath;
  inherit (lib.lists) any concatMap elem head optionals;
  inherit (lib.modules) mkDefault;
  inherit (_.modules.core) mkSudoRules;
  inherit (_.attrsets.resolution) package;
  inherit (_.applications.firefox) zenVariant;
  inherit (_.lists.predicates) isIn isNotIn;

  mkUsers = {
    host,
    pkgs,
    inputs,
    specialArgs,
    ...
  }: let
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
    users.users =
      mapAttrs (name: cfg: {
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
          ++ optionals (isNotIn (cfg.role or null) ["service"]) ["users"]
          ++ optionals (isIn (cfg.role or null) ["admin" "administrator"]) ["wheel"]
          ++ optionals (host.devices.network != []) ["networkmanager"]
          ++ [];
      })
      users;

    home-manager = {
      backupFileExtension = "BaC";
      overwriteBackup = true;
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = specialArgs;

      #> Merge all per-user home-manager configs
      users =
        mapAttrs (name: cfg: {
          _module.args.user = cfg // {inherit name;};
          imports =
            cfg.imports or []
            ++ (with inputs.modules.home; [
              nvf
              noctalia-shell
              dank-material-shell
              plasma
              zen-browser
            ])
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
  };

  exports = {inherit mkUsers;};
in
  exports // {_rootAliases = exports;}
