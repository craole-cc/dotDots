{
  _,
  lib,
  ...
}: let
  inherit (lib.attrsets) filterAttrs mapAttrs;
  inherit (lib.lists) elem head optionals;
  inherit (lib.strings) hasInfix;
  inherit (_.attrsets.resolution) package;
  inherit (_.lists.predicates) isIn;

  mkSudoRules = admins:
    map (name: {
      #> Apply this rule only to the named user.
      users = [name];

      #> Allow that user to run any command as any user/group, without password.
      #? Equivalent to: name ALL=(ALL:ALL) NOPASSWD: ALL
      commands = [
        {
          command = "ALL";
          options = ["SETENV" "NOPASSWD"];
        }
      ];
    })
    admins;

  mkUsers = {
    host,
    pkgs,
    homeModules,
    specialArgs,
    src,
    ...
  }: let
    users = host.users.data.enabled or {};
    admins = host.users.names.elevated or [];
  in {
    users = {
      #> Create a private group for each user
      #? This ensures the primary group exists before user creation
      groups = mapAttrs (_: _: {}) users;

      users =
        mapAttrs (name: cfg: {
          isNormalUser = cfg.role != "service";
          isSystemUser = cfg.role == "service";
          description = cfg.description or name;
          password = cfg.password or null;
          group = name;
          extraGroups =
            []
            ++ optionals (!isIn (cfg.role or null) ["service"]) ["users"]
            ++ optionals (isIn (cfg.role or null) ["admin" "administrator"]) ["wheel"]
            ++ optionals (host.devices.network != []) ["networkmanager"]
            ++ [];
          shell = package {
            inherit pkgs;
            target = head (cfg.shells or ["bash"]);
          };
        })
        users;
    };

    home-manager = {
      backupFileExtension = "BaC";
      overwriteBackup = true;
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = specialArgs // {inherit homeModules;};

      #> Merge all per-user home-manager configs
      users =
        mapAttrs (name: cfg: {
          home = {inherit (host) stateVersion;};
          _module.args.user = cfg // {inherit name;};
          imports = let
            zen-browser = rec {
              isAllowed = hasInfix "zen" (cfg.applications.browser.firefox or "");
              variant =
                if hasInfix "twilight" (cfg.applications.browser.firefox or "")
                then "twilight"
                else "default";
              module = homeModules.zen-browser.${variant} or {};
            };

            noctalia-shell = rec {
              isAllowed = hasInfix "noctalia" (cfg.interface.bar or "");
              variant = "default";
              module = homeModules.noctalia-shell.${variant} or {};
            };
          in
            [(src + "/Packages/home")]
            ++ optionals (noctalia-shell.isAllowed) [noctalia-shell.module]
            ++ optionals (zen-browser.isAllowed) [zen-browser.module]
            ++ (cfg.imports or []);
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

  exports = {inherit mkUsers mkSudoRules;};
in
  exports // {_rootAliases = exports;}
