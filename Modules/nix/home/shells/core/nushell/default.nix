{
  config,
  host,
  lix,
  paths,
  pkgs,
  user,
  ...
}: let
  dom = "shells";
  sub = "core";
  mod = "nushell";
  context = mkContext {inherit config dom sub mod;};
  inherit (context) cfg;
  inherit (lix.attrsets.access) attrNames;
  inherit (lix.filesystem.access) readFile readDir;
  inherit (lix.filesystem.construction) concatPath;
  inherit (lix.filesystem.predicates) pathExists;
  inherit (lix.lists.transformation) filter;
  inherit (lix.lists.predicates) isIn;
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.strings.construction) concat optionalString tokenize;
  inherit (lix.strings.predicates) hasPrefix hasSuffix;
  inherit (lix.strings.transformation) removePrefix removeSuffix;
  inherit (lix.types.combinators) attrsOf listOf;
  inherit (lix.toolkit) packages;
  inherit (lix.types.primitives) anything lines package;

  dotsrc = concatPath {
    root = paths.repo.src.store;
    stem = ".dotsrc";
  };

  nuSection = concat "\n" (map
    (line: removePrefix "#nu " line)
    (
      filter (line: hasPrefix "#nu " line) (
        tokenize "\n" (optionalString (pathExists dotsrc) (readFile dotsrc))
      )
    )
  );

  defaults = {
    inherit (import ./settings.nix) settings;
    enable = host.interface.shell.interactive == mod;
    package = packages.nushell;
    extra = {
      env = ''
        $env.DOTS = ($env.DOTS? | default "${paths.repo.src.local}")
        $env.DOTS_RC = ($env.DOTS | path join ".dotsrc")
      '';
      config = concat "\n" [
        nuSection
        (
          concat "\n" (map (name: ''
            def ${name} [...args] { ^${concatPath {
              root = paths.repo.lib.nu.local;
              stem = "${name}.nu";
            }} ...$args }
          '') (
            map (name: removeSuffix ".nu" name) (
              filter (name: hasSuffix ".nu" name) (
                attrNames (readDir paths.repo.lib.nu.store)
              )
            )
          ))
        )
      ];
      packages = with pkgs; [nufmt nu_scripts];
    };
  };
in
  mkConfig {
    inherit context defaults;
    options = {
      enable = mkEnable {
        inherit context;
        condition = isIn mod ((user.shells or []) ++ (user.applications.allowed or []));
      };
      package = mkOption {
        type = package;
        default = defaults.package;
        description = "Nushell package to install.";
      };
      settings = mkOption {
        type = attrsOf anything;
        default = defaults.settings;
        description = "Nushell configuration settings.";
      };
      extra = {
        env = mkOption {
          type = lines;
          default = defaults.extra.env;
          description = "Environment configuration loaded by Nushell.";
        };
        config = mkOption {
          type = lines;
          default = defaults.extra.config;
          description = "Additional Nushell startup configuration.";
        };
        packages = mkOption {
          type = listOf package;
          default = defaults.extra.packages;
          description = "Additional packages to install alongside Nushell.";
        };
      };
    };
    outputs = {
      programs.nushell = {
        inherit (cfg) enable package settings;
        extraEnv = cfg.extra.env;
        extraConfig = cfg.extra.config;
      };
      home = {inherit (cfg.extra) packages;};
    };
  }
