{
  _,
  lib,
  ...
}: let
  inherit (_.lists.predicates) mostFrequent;
  inherit (lib.attrsets) attrNames genAttrs mapAttrs mapAttrsToList;
  inherit (lib.lists) flatten last unique;

  getSystems = {
    # path ? src,
    hosts ? {},
    nixpkgs ? {},
    legacyPackages ? {},
  }: let
    pkgsBase =
      if legacyPackages != {}
      then legacyPackages
      else if nixpkgs ? legacyPackages
      then nixpkgs.legacyPackages
      # else (getInputs {}).inputs.nixpkgs.legacyPackages or {};
      else {};

    #> Extract and flatten defined systems
    defined = flatten (mapAttrsToList (_: host: host.platform or host.system or []) hosts);

    #> Default systems in alphabetical order
    default = [
      "aarch64-darwin"
      "aarch64-linux"
      "x86_64-darwin"
      "x86_64-linux"
    ];

    #> Get most common defined system, or tail of default
    derived = let
      common = mostFrequent defined null;
    in
      if common != null
      then common
      else last default;

    all = unique (defined ++ default);
    per = genAttrs all;
    pkgsFor = system: pkgsBase.${system} or {};

    #> Provide perFlake pkgs automatically
    perFlake = fn: let
      perSystemOutputs = per (
        system:
          fn {
            inherit system;
            pkgs = pkgsFor system;
          }
      );
      outputNames = attrNames (fn {
        system = derived;
        pkgs = pkgsFor derived;
      });
    in
      genAttrs outputNames (
        outputName: mapAttrs (_: systemOutputs: systemOutputs.${outputName}) perSystemOutputs
      );
  in {
    inherit
      all
      default
      derived
      defined
      per
      pkgsFor
      perFlake
      ;
    system = derived;
    inherit pkgsBase;
    pkgs = pkgsFor derived;
  };

  getSystem = pkgs: pkgs.stdenv.hostPlatform.system;

  perFlake = {
    hosts ? {},
    nixpkgs ? {},
    legacyPackages ? {},
  }:
    (getSystems {inherit hosts nixpkgs legacyPackages;}).perFlake;

  exports = {
    inherit getSystem getSystems perFlake;
    getSystemsPerFlake = perFlake;
  };
in
  exports
  // {
    _rootAliases = {
      inherit
        (exports)
        getSystem
        getSystems
        getSystemsPerFlake
        ;
    };
  }
