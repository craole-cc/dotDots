{
  lib ? import <nixpkgs/lib>,
  src ? ./.,
  system ? builtins.currentSystem,
  pkgs ? import <nixpkgs> {inherit system;},
  ...
}: let
  #──────────────────────────────────────────────────────────────────────────────
  # Core Imports
  #──────────────────────────────────────────────────────────────────────────────
  inherit (import ./Libraries {inherit lib src;}) lix;
  inherit (import ./API {inherit lix;}) hosts users;

  inherit (lib.attrsets) attrByPath attrNames attrValues filterAttrs listToAttrs mapAttrs;
  inherit (lib.lists) length filter head findFirst;
  inherit (lib.strings) splitString;
  inherit (lix.configuration.predicates) isSystemDefaultUser;

  #──────────────────────────────────────────────────────────────────────────────
  # Flake Resolution
  #──────────────────────────────────────────────────────────────────────────────

  lic = lix.configuration.resolution;
  flake = lic.flake {path = src;};
  nixosConfigurations = flake.nixosConfigurations or {};

  systems = lic.systems {inherit hosts;};
  systemPkgs = systems.pkgs;
  currentSystem = systems.system;

  #──────────────────────────────────────────────────────────────────────────────
  # Host Resolution
  #──────────────────────────────────────────────────────────────────────────────

  # Find a host that matches current system
  matchingHost =
    findFirst
    (host: host.config.nixpkgs.hostPlatform.system or null == currentSystem)
    null
    (attrValues nixosConfigurations);

  # Get the current host
  currentHost =
    if matchingHost != null
    then matchingHost
    else head (attrValues nixosConfigurations);

  host = lic.host {inherit nixosConfigurations system;};
  inherit (currentHost.config.networking) hostName;

  # Create enhanced host info
  hostData = {
    name = hostName;
    platform = currentHost.config.nixpkgs.hostPlatform.system;
    paths = {
      dots = src;
      bin = src + "/Bin";
    };
  };

  #──────────────────────────────────────────────────────────────────────────────
  # REPL Helpers
  #──────────────────────────────────────────────────────────────────────────────

  helpers = {
    #~@ Script generators (copy-paste ready)
    scripts = {
      rebuild = host: "sudo nixos-rebuild switch --flake .#${host}";
      test = host: "sudo nixos-rebuild test --flake .#${host}";
      boot = host: "sudo nixos-rebuild boot --flake .#${host}";
      dry = host: "sudo nixos-rebuild dry-build --flake .#${host}";
      update = "nix flake update";
      clean = "sudo nix-collect-garbage -d";
    };

    #~@ Host discovery
    listHosts = attrNames nixosConfigurations;
    getHost = name: nixosConfigurations.${name} or null;

    #~@ Host information
    hostInfo = name: let
      host = nixosConfigurations.${name};
      cfg = host.config;
      allUsers = attrNames cfg.users.users;

      version = {
        kernel = cfg.boot.kernelPackages.kernel.version;
        state = cfg.system.stateVersion;
        nixos = cfg.system.nixos.version;
      };

      userList = {
        custom = filter (u: !isSystemDefaultUser u) allUsers;
        system = filter isSystemDefaultUser allUsers;
      };

      usersData = listToAttrs (map (user: {
          name = user;
          value = {
            core = cfg.users.users.${user};
            home = let hm = cfg.home-manager.users.${user}; in hm // hm.home;
            api = users.${user};
          };
        })
        userList.custom);

      # Helper to safely get attributes with fallback
      getHomeAttr = attr: user: user.home.${attr} or {};
      getApiAttr = attr: user: user.api.${attr} or {};

      # Generic config section maker with three sources
      mkConfigSection = corePath: homeAttr: apiAttr: {
        core = attrByPath (splitString "." corePath) {} host.config;
        home =
          if length (attrNames usersData) == 1
          then getHomeAttr homeAttr (head (attrValues usersData))
          else mapAttrs (name: user: getHomeAttr homeAttr user) usersData;
        api =
          if length (attrNames usersData) == 1
          then getApiAttr apiAttr (head (attrValues usersData))
          else mapAttrs (name: user: getApiAttr apiAttr user) usersData;
      };

      programs = mkConfigSection "programs" "programs" "programs";
      services = mkConfigSection "services" "services" "services";
      variables = mkConfigSection "environment.sessionVariables" "sessionVariables" "variables";
      aliases = mkConfigSection "environment.shellAliases" "shellAliases" "aliases";
      packages = mkConfigSection "environment.systemPackages" "packages" "packages";

      desktopEnvironment = with cfg.services.desktopManager;
        if plasma6.enable or false
        then "plasma"
        else if gnome.enable or false
        then "gnome"
        else if cosmic.enable or false
        then "cosmic"
        else null;
    in {
      inherit
        version
        usersData
        userList
        desktopEnvironment
        programs
        services
        variables
        aliases
        packages
        ;
      users = usersData;
      inherit (cfg.networking) hostName;
      inherit (cfg.nixpkgs.hostPlatform) system;
    };

    #~@ Host comparison
    compareHosts = host1: host2: let
      h1 = nixosConfigurations.${host1};
      h2 = nixosConfigurations.${host2};
    in {
      systems = {
        "${host1}" = h1.config.nixpkgs.hostPlatform.system;
        "${host2}" = h2.config.nixpkgs.hostPlatform.system;
      };
      kernels = {
        "${host1}" = h1.config.boot.kernelPackages.kernel.version;
        "${host2}" = h2.config.boot.kernelPackages.kernel.version;
      };
      stateVersions = {
        "${host1}" = h1.config.system.stateVersion;
        "${host2}" = h2.config.system.stateVersion;
      };
    };

    #~@ Service queries
    hostsWithService = service:
      attrNames (filterAttrs
        (name: host: attrByPath (splitString "." service) false host.config)
        nixosConfigurations);

    enabledServices = hostName: let
      host = nixosConfigurations.${hostName};
      services = host.config.systemd.services;
    in
      attrNames (filterAttrs (n: v: v.enable or false) services);
  };

  #──────────────────────────────────────────────────────────────────────────────
  # CLI Tools
  #──────────────────────────────────────────────────────────────────────────────

  inherit (pkgs) writeShellScriptBin;

  # Create the main dotDots script using rust-script
  rustScript = writeShellScriptBin "dotDots" ''
    #!/usr/bin/env bash
    exec ${pkgs.rust-script}/bin/rust-script ${src}/Bin/rust/.dots.rs "$@"
  '';

  # Create REPL command
  replCmd = writeShellScriptBin ".repl" ''
    #!/usr/bin/env bash
    exec nix repl --file ${src}/default.nix
  '';

  # Create wrapper scripts for each command
  mkCmd = cmd:
    writeShellScriptBin ".${cmd}" ''
      #!/usr/bin/env bash
      exec ${rustScript}/bin/dotDots ${cmd} "$@"
    '';

  commands =
    listToAttrs (
      map
      (cmd: {
        name = ".${cmd}";
        value = mkCmd cmd;
      })
      [
        #~@ Core commands
        "hosts"
        "info"
        "rebuild"
        "test"
        "boot"
        "dry"
        "update"
        "clean"
        "sync"
        "binit"
        "list"
        "help"

        #TODO: These dont work yet, make them aliases
        #~@ Workflow commands
        "flick"
        "flush"
        "fmt"
        "fo"
        "ff"
        "flow"
        "flare"
        "ft"
      ]
    )
    // {".repl" = replCmd;};

  packages = with pkgs;
    [
      #~@ Core tools
      bat #? cat clone with syntax highlighting
      fd #? fast alternative to 'find'
      gitui #? TUI interface for git
      gnused #? GNU sed for text processing
      jq #? JSON processor and query tool
      nil #? Nix language server
      nixd #? Alternative Nix language server
      onefetch #? Git repo info viewer (instant project summary)
      tokei #? Counts lines of code per language
      undollar #? Replaces shell variable placeholders easily
      yazi #? TUI file manager with vim-like controls

      #~@ Git tools
      gh #? GitHub CLI for authentication switching

      #~@ Rust toolchain (for building dots-cli)
      rustc #? Rust compiler
      cargo #? Rust package manager and build system
      rust-analyzer #? Rust language server (LSP)
      rustfmt #? Rust code formatter
      rust-script #? Run Rust files as scripts

      #~@ Clipboard dependencies
      xclip #? Clipboard utility for X11
      wl-clipboard #? Clipboard utility for Wayland
      xsel #? Another X11 clipboard interaction tool

      #~@ Formatters
      alejandra #? Nix code formatter
      markdownlint-cli2 #? Markdown linter and style checker
      nixfmt #? Alternative Nix formatter
      shellcheck #? Linter for shell scripts
      shfmt #? Shell script formatter
      taplo #? TOML formatter and linter
      treefmt #? Unified formatting tool for multiple languages
      yamlfmt #? YAML formatter
    ]
    ++ (attrValues commands)
    ++ [rustScript];

  #──────────────────────────────────────────────────────────────────────────────
  # Development Shell
  #──────────────────────────────────────────────────────────────────────────────

  env = with hostData.paths; {
    NIX_CONFIG = "experimental-features = nix-command flakes";
    DOTS = dots;
    DOTS_BIN = bin;
    ENV_BIN = dots + "/.direnv/bin";
    HOST_NAME = hostData.name;
    HOST_TYPE = hostData.platform;
  };

  shellHook = ''
    #> Create directory for wrapper scripts
    mkdir -p "$ENV_BIN"

    #> Add bin directory to PATH
    export PATH="$ENV_BIN:$PATH"

    #> Initialize bin directories
    if command -v dotDots >/dev/null 2>&1; then
      # Silently eval binit to add all bin directories to PATH
      eval "$(dotDots binit)" 2>/dev/null || true
    fi

    #> Display a welcome message
    if command -v dotDots >/dev/null 2>&1; then
      dotDots help
    else
      printf "🎯 NixOS Configuration REPL\n"
      printf "============================\n"
      printf "\n"
      printf "Current host: $HOST_NAME\n"
      printf "System: $HOST_TYPE\n"
      printf "\n"
      printf "Type '.help' for available commands\n"
      printf "Type 'dotDots help' for more options\n"
      printf "Type '.repl' to enter Nix REPL\n"
      printf "Type '.sync [message]' to commit & push all changes\n\n"
    fi
  '';

  shell = pkgs.mkShell {
    name = "dotDots";
    inherit packages env shellHook;
  };

  #──────────────────────────────────────────────────────────────────────────────
  # REPL Interface
  #──────────────────────────────────────────────────────────────────────────────

  replInterface = {
    inherit
      lix
      lib
      builtins
      helpers
      flake
      ;

    #~@ Top-level host attributes
    inherit
      (host)
      config
      options
      ;

    inherit (host._module) specialArgs;
    inherit (flake) inputs;

    #~@ Convenient shortcuts to config sections
    inherit
      (helpers.hostInfo host.name)
      users
      aliases
      packages
      programs
      services
      variables
      ;

    inherit pkgs system;

    #~@ Development shell
    inherit shell;
  };
in
  # When used as a REPL, expose the interface
  # When used for development, expose everything including shell
  replInterface
  // {
    # Export these for external use
    inherit lix users hosts shell;

    # Make the API accessible
    api = {inherit users hosts;};
  }
