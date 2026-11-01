{
  config,
  options,
  lix,
  inputs,
  pkgs,
  user,
  ...
}: let
  inherit (lix.attrsets.aggregation) recursiveUpdate;
  inherit (lix.lists.predicates) isIn;
  inherit (lix.modules.construction) mkConfig mkContext mkLayer;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.lists.transformation) filter;
  inherit (lix.toolkit) packages fetch;
  inherit (lix.sources.packages) pkgOf;
  inherit (lix.strings.transformation) replaceStrings;
  inherit (lix.types.combinators) nullOr attrs;
  pkgType = nullOr lix.types.primitives.package;

  system = pkgs.stdenv.hostPlatform.system;
  warpInput = inputs."warp-terminal";
  warpPackage = warpInput.packages.${system}.default.overrideAttrs (
    previous: let
      release = replaceStrings [".preview."] [".preview_"] previous.version;
    in {
      # The rolling download can advance before the input's version and hash do.
      src = fetch.fromUrl {
        inherit (previous.src) name;
        hash = previous.src.outputHash;
        url = "https://releases.warp.dev/preview/v${release}/warp-terminal-preview_${previous.version}_${
          if system == "aarch64-linux"
          then "arm64"
          else "amd64"
        }.deb";
      };
    }
  );

  context = mkContext {
    inherit config;
    dom = "terminal";
    sub = "emulators";
    mod = "warp-terminal";
  };
  inherit (context) cfg mod;

  packageRecord = package: enableAlias:
    removeAttrs (pkgOf {
      inherit pkgs;
      inputs = recursiveUpdate inputs {
        "warp-terminal".packages.${system}.default = package;
      };
      input = "warp-terminal";
      alias =
        if enableAlias
        then mod
        else null;
      exe = "warp";
      required = true;
    }) ["exeOf"];

  defaults = {
    enable = false;
    enableAlias = true;
    package = packages.warp-terminal;
    pkg = packageRecord defaults.package defaults.enableAlias;
    alias = defaults.pkg.alias;
    home = {
      packages = [defaults.package defaults.alias];
      sessionVariables = {};
      shellAliases = {};
    };
  };

  resolved = {
    enable = isIn [mod "warp-preview" "warp"] ((user.packages.terminal or []) ++ (user.applications.allowed or []));
    package = warpPackage;
    pkg = packageRecord cfg.package cfg.enableAlias;
  };
in
  mkConfig {
    inherit context defaults;
    options = {
      enable = mkEnable {
        inherit context;
        condition = defaults.enable;
      };
      enableAlias = mkEnable {
        description = "${mod} command alias";
        condition = defaults.enableAlias;
      };
      alias = mkOption {
        description = "Alias (${mod}) for the executable";
        default = cfg.pkg.alias;
        readOnly = true;
        type = pkgType;
      };
      package = mkOption {
        description = "Warp terminal package to install";
        default = defaults.package;
        type = pkgType;
      };
      pkg = mkOption {
        description = "Resolved Warp package metadata and command alias";
        default = resolved.pkg;
        readOnly = true;
        type = attrs;
      };
      home = {
        packages = mkOption {
          description = "Packages installed for Warp, including its optional command alias";
          inherit (options.home.packages) type;
          default = defaults.home.packages;
        };
        sessionVariables = mkOption {
          description = "Session variables provided by Warp";
          inherit (options.home.sessionVariables) type;
          default = defaults.home.sessionVariables;
        };
        shellAliases = mkOption {
          description = "Shell aliases provided by Warp";
          inherit (options.home.shellAliases) type;
          default = defaults.home.shellAliases;
        };
      };
    };
    resolutions = mkLayer 1000 {
      inherit (resolved) enable package;
      home.packages = filter (package: package != null) [cfg.package cfg.alias];
    };
    outputs = {inherit (cfg) home;};
  }
