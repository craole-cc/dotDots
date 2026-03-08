{
  _,
  lib,
  ...
}: let
  inherit (_.filesystem.paths) source;
  inherit (_.modules.resolution) getSystem;
  inherit
    (lib.attrsets)
    filterAttrsRecursive
    listToAttrs
    mapAttrs
    attrByPath
    mapAttrs'
    ;
  inherit (_.inputs.resolution) inputs;

  defaults = {
    allowUnfree = true;
    allowBroken = false;

    corePackages = [
      "nixpkgs"
      "nixpkgs-stable"
      "nixpkgs-unstable"
    ];

    homePackages = [
      "caelestia"
      "catppuccin"
      "dank-material-shell"
      "fresh-editor"
      "helix"
      "home-manager"
      "noctalia-shell"
      "nvf"
      "plasma"
      "quickshell"
      "treefmt"
      "typix"
      "vscode-insiders"
      "zen-browser"
    ];
  };

  mkPackageSet = {
    attr,
    names,
  }:
    listToAttrs (map (name: {
        inherit name;
        value = attrByPath [name attr] {} inputs;
      })
      names);

  packages =
    mkPackageSet {
      attr = "legacyPackages";
      names = defaults.corePackages;
    }
    // mkPackageSet {
      attr = "packages";
      names = defaults.homePackages;
    };

  mkPackages = {host}: let
    config = let
      pkgs = host.packages;
    in {
      allowUnfree = pkgs.allowUnfree or defaults.allowUnfree;
      allowBroken = pkgs.allowBroken or defaults.allowBroken;
    };
    overlays = mkOverlays {inherit config;};
    nixpkgs = let
      hostPlatform = host.system;
      sourcePath = source {inherit host inputs;};
    in
      {inherit config overlays hostPlatform;} // sourcePath;
  in {inherit nixpkgs inputs packages overlays;};

  mkOverlays = {config ? {}}: let
    config' =
      {inherit (defaults) allowUnfree allowBroken;}
      // config;
  in [
    #~@ Stable
    (final: _: let
      system = getSystem final;
    in {
      fromStable = import inputs.nixpkgs-stable {
        config = config';
        inherit system;
      };
    })

    #~@ Unstable
    (final: _: let
      system = getSystem final;
    in {
      fromUnstable = import inputs.nixpkgs-unstable {
        config = config';
        inherit system;
      };
    })

    #~@ Flake inputs
    #? Flattened packages (higher priority)
    (final: prev: let
      system = getSystem prev;
    in
      filterAttrsRecursive (_: value: value != null) (
        mapAttrs' (name: pkgsSet: {
          inherit name;
          value = attrByPath [system "default"] null pkgsSet;
        })
        packages
      ))

    #? Categorized (lower priority, for browsing)
    (final: prev: let
      system = getSystem prev;
    in {
      fromInputs =
        mapAttrs (_: pkgsSet: attrByPath [system] {} pkgsSet) packages;
    })

    #~@ Chaotic overlay
    (inputs.chaotic.overlays.default or (_: _: {}))
  ];

  exports = {
    inherit
      defaults
      mkOverlays
      mkPackageSet
      mkPackages
      packages
      ;
    getInputDefaults = defaults;
    getInputPackages = packages;
    mkInputOverlays = mkOverlays;
    mkInputPackageSet = mkPackageSet;
    mkInputPackages = mkPackages;
  };
in
  exports
  // {
    _rootAliases = {
      inherit
        (exports)
        getInputDefaults
        getInputPackages
        mkInputPackageSet
        mkInputOverlays
        mkInputPackages
        ;
    };
  }
