{
  _,
  lib,
  ...
}: let
  inherit
    (lib.attrsets)
    attrValues
    attrNames
    attrByPath
    filterAttrs
    optionalAttrs
    mapAttrs
    mapAttrsToList
    ;
  inherit
    (lib.lists)
    filter
    concatLists
    elem
    head
    length
    unique
    ;
  inherit (lib.modules) mkIf mkDefault;
  inherit (lib.lists) optional;
  inherit (_.applications.firefox) zenVariant;
  inherit (_.attrsets.resolution) package;

  mkAdmin = name: {
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
  };

  isAdmin = u: elem (u.role or null) ["admin" "administrator"];

  mkUsers = {
    host,
    inputs,
    extraArgs,
  }: {
    config,
    pkgs,
    ...
  }: let
    inherit (host) stateVersion interface system users;
    inherit (inputs) nixosHome firefoxZen plasmaManager;

    #> Collect all enabled regular users (non-service, non-guest)
    normalUsers = filterAttrs (_: u: !(elem u.role ["service" "guest"])) users;

    userNames = attrValues (attrNames host.users or {});
    #> Collect all enabled users with elevated privelages
    adminsUsersRaw = filterAttrs (_: isAdmin) host.users;
    adminUsers =
      if adminsUsersRaw != {}
      then adminsUsersRaw
      else if length userNames == 1
      then let name = head userNames; in {${name} = users.${name};}
      else adminsUsersRaw;

    #> Determine which DE/WM/DM to enable based on user preferences
    #? Priority: user config > host config > null
    interfaces = let
      # Build per-user interface config with host fallback
      userInterfaces =
        mapAttrs (name: cfg: {
          desktopEnvironment = cfg.interface.desktopEnvironment or interface.desktopEnvironment or null;
          windowManager = cfg.interface.windowManager or interface.windowManager or null;
          displayManager = cfg.interface.displayManager or interface.displayManager or null;
        })
        normalUsers;

      # Collect all unique requested environments
      desktopEnvironments = unique (filter (x: x != null) (
        attrValues (mapAttrs (_: i: i.desktopEnvironment) userInterfaces)
      ));
      windowManagers = unique (filter (x: x != null) (
        attrValues (mapAttrs (_: i: i.windowManager) userInterfaces)
      ));
      loginManagers = unique (filter (x: x != null) (
        attrValues (mapAttrs (_: i: i.displayManager) userInterfaces)
      ));
    in {
      inherit desktopEnvironments windowManagers loginManagers userInterfaces;
    };

    #> Enable flags based on collected interfaces
    enableHyprland = elem "hyprland" interfaces.windowManagers;
    enableNiri = elem "niri" interfaces.windowManagers;
    enablePlasma = elem "plasma" interfaces.desktopEnvironments;
    enableGnome = elem "gnome" interfaces.desktopEnvironments;

    #> Determine login manager (prefer user choice, fallback to DE defaults)
    displayManager =
      if enablePlasma && !enableGnome
      then "sddm"
      else if enableGnome && !enablePlasma
      then "gdm"
      else if interfaces.loginManagers != []
      then head interfaces.loginManagers
      else null;

    enableSddm = displayManager == "sddm";
    enableGdm = displayManager == "gdm";

    #> Collect all unique shells from all users
    allShells = let
      shellsList = concatLists (
        attrValues (mapAttrs (_: cfg: cfg.shells or ["bash"]) normalUsers)
      );
    in
      unique shellsList;

    #> Helper to get user's interface preference (already resolved with host fallback)
    getUserInterface = name: attr:
      interfaces.userInterfaces.${name}.${attr} or null;

    #> Generate per-user configuration sections
    perUserConfigs =
      mapAttrs (name: cfg: let
        isNormalUser = cfg.role != "service";
        zen = zenVariant (attrByPath ["applications" "browser" "firefox"] null cfg);
        dp = getUserInterface name "displayProtocol";
        de = getUserInterface name "desktopEnvironment";
        wm = getUserInterface name "windowManager";
        # TODO: Move this to it's own file
        policies = let
          hasFun = f: elem f (host.functionalities or []);
          hasCap = c: elem c (host.capabilities or []);

          hasInternet = hasFun "wired" || hasFun "wireless";
          hasGui = hasFun "video";
          hasAudio = hasFun "audio";
        in {
          web = hasInternet;
          webGui = hasInternet && hasGui;
          dev = hasCap "development";
          devGui = hasCap "development" && hasGui;
          media = (hasCap "multimedia" || hasCap "creation") && hasAudio && hasGui;
          webMedia = hasInternet && hasAudio && hasGui;
          productivity = (hasCap "writing" || hasCap "analysis" || hasCap "management") && hasGui;
          gaming = hasCap "gaming" && hasGui;
        };
      in {
        #> This user's NixOS account config
        nixosUser = {
          inherit isNormalUser;
          isSystemUser = !isNormalUser;
          description = cfg.description or name;

          #> Use first shell as default
          shell = package {
            inherit pkgs;
            target = head (cfg.shells or ["bash"]);
          };

          password = cfg.password or null;

          extraGroups =
            (
              if elem (cfg.role or null) ["admin" "administrator"]
              then ["wheel"]
              else []
            )
            ++ (
              if
                isNormalUser
                && (config.networking.networkmanager.enable or false)
              then ["networkmanager"]
              else []
            );
        };

        #> This user's home-manager config
        homeConfig = {
          _module.args = {
            user = cfg // {inherit name;};
            inherit policies;
          };
          imports =
            (cfg.imports or [])
            #> Add Firefox Zen module if user prefers the Zen variant.
            ++ optional (zen != null) firefoxZen.homeModules.${zen}
            #> Add Plasma Manager module if user uses Plasma desktop
            ++ optional (de == "plasma") plasmaManager.homeModules.plasma-manager
            ++ [];

          home = {
            inherit stateVersion;
            sessionVariables =
              {
                USER_ROLE = cfg.role or "user";
                EDITOR = let
                  editor = attrByPath ["applications" "editor" "tty" "primary"] "nano" cfg;
                in
                  if editor == "helix"
                  then "hx"
                  else if editor == "neovim"
                  then "nvim"
                  else editor;
                VISUAL =
                  attrByPath ["applications" "editor" "gui" "primary"] (
                    if de == "gnome"
                    then "gnome-text-editor"
                    else if de == "plasma"
                    then "kate"
                    else "code"
                  )
                  cfg;
                BROWSER = let
                  browser = attrByPath ["applications" "browser" "primary"] "firefox" cfg;
                in
                  if browser == "zen"
                  then "zen-${zen}"
                  else browser;
                # TERMINAL =
                #   attrByPath ["applications" "terminal" "primary"] (
                #     if de == "gnome"
                #     then "gnome-terminal"
                #     else if de == "plasma"
                #     then "konsole"
                #     else if wm == "hyprland"
                #     then "kitty"
                #     else "footclient"
                #   )
                # cfg;
              }
              // (
                optionalAttrs (dp == "wayland" || enableHyprland || enableNiri) {
                  #? For Clutter/GTK apps
                  CLUTTER_BACKEND = "wayland";

                  #? For GTK apps
                  GDK_BACKEND = "wayland";

                  #? Required for Java UI apps on Wayland
                  _JAVA_AWT_WM_NONREPARENTING = "1";

                  #? Enable Firefox native Wayland backend
                  MOZ_ENABLE_WAYLAND = "1";

                  #? Force Chromium/Electron apps to use Wayland
                  NIXOS_OZONE_WL = "1";

                  #? Qt apps use Wayland
                  QT_QPA_PLATFORM = "wayland";

                  #? Disable client-side decorations for Qt apps
                  QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";

                  #? Auto scale for HiDPI displays
                  QT_AUTO_SCREEN_SCALE_FACTOR = "1";

                  #? SDL2 apps Wayland backend
                  SDL_VIDEODRIVER = "wayland";

                  #? Allow software rendering fallback on Nvidia/VM
                  WLR_RENDERER_ALLOW_SOFTWARE = "1";

                  #? Disable hardware cursors on Nvidia/VM
                  WLR_NO_HARDWARE_CURSORS = "1";

                  #? Indicate Wayland session to apps
                  XDG_SESSION_TYPE = "wayland";
                }
              );
            packages =
              (map (shell:
                package {
                  inherit pkgs;
                  target = shell;
                })
              allShells)
              ++ (
                if wm == "hyprland"
                then [pkgs.kitty]
                else []
              )
              ++ (
                if de == "plasma"
                then
                  with pkgs;
                    [karp deno]
                    ++ (with kdePackages; [
                      yakuake
                      koi
                      krohnkite
                    ])
                else []
              )
              ++ [];
          };

          #> Enable shells in home-manager
          programs = {
            bash.enable = mkDefault (elem "bash" (cfg.shells or []));
            zsh.enable = mkDefault (elem "zsh" (cfg.shells or []));
            fish.enable = mkDefault (elem "fish" (cfg.shells or []));
            nushell.enable = mkDefault (elem "nushell" (cfg.shells or []));
            zen-browser =
              mkIf (zen != null) {
                enable = true;
                package =
                  firefoxZen.packages.${system}.${zen} or
            (throw "Firefox Zen variant '${zen}' not found for system '${system}'");
              };
          };

          wayland.windowManager.hyprland.enable = wm == "hyprland";
        };
      })
      normalUsers;
  in {
    # Policy check:
    # - If multiple users exist, at least one must be an administrator.
    # - A single-user host may omit role and will be auto-promoted to admin.
    assertions = [
      {
        assertion = (adminUsers != {}) || (length userNames <= 1);
        message = ''
          When multiple users are defined for a host, at least one must have role = "administrator".
        '';
      }
    ];

    #~@ System-wide NixOS users
    users.users = mapAttrs (name: cfg: cfg.nixosUser) perUserConfigs;

    #~@ Admin privelages
    security.sudo = {
      #> Restrict sudo to members of the wheel group (root is always allowed).
      execWheelOnly = true;

      #> For each admin user, grant passwordless sudo for all commands.
      extraRules = mapAttrsToList (name: _: mkAdmin name) adminUsers;
    };

    #~@ System-wide programs (not per-user)
    programs = {
      bash.blesh.enable = true;
      hyprland = mkIf enableHyprland {
        enable = true;
        withUWSM = true;
      };

      niri = mkIf enableNiri {
        enable = true;
      };

      git = {
        enable = true;
        lfs.enable = true;
        prompt.enable = true;
      };

      gnupg.agent = {
        enable = true;
        enableSSHSupport = true;
      };

      xwayland.enable = true;
    };

    services = {
      displayManager = {
        sddm = mkIf enableSddm {
          enable = true;
          wayland.enable = true;
        };
        gdm = mkIf enableGdm {
          enable = true;
        };

        #> Auto-login for first user with autoLogin = true
        autoLogin = let
          autoLoginUsers = filterAttrs (_: u: u.autoLogin or false) normalUsers;
          autoLoginUser =
            if autoLoginUsers != {}
            then head (attrNames autoLoginUsers)
            else null;
        in
          mkIf (autoLoginUser != null) {
            enable = true;
            user = autoLoginUser;
          };
      };

      desktopManager = {
        plasma6.enable = enablePlasma;
        gnome.enable = enableGnome;
      };
    };

    imports = [nixosHome.nixosModules.home-manager];
    home-manager = {
      backupFileExtension = "BaC";
      overwriteBackup = true;
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = extraArgs // {inherit users;};

      #> Merge all per-user home-manager configs
      users = mapAttrs (name: cfg: cfg.homeConfig) perUserConfigs;
    };
  };
in {
  inherit
    mkUsers
    ;
}
