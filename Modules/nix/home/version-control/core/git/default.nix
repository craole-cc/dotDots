{
  config,
  entryAfter,
  lix,
  inputs,
  pkgs,
  user,
  ...
}: let
  inherit (lix.modules.construction) mkContext mkConfig;
  inherit (lix.sources.packages) pkgsFrom;

  context = mkContext {
    inherit config;
    dom = "version-control";
    sub = "core";
    mod = "git";
  };

  defined = user.git;

  tool = let
    all = pkgsFrom {
      inherit inputs pkgs;
      sources = {
        #? `null` means taken from nixpkgs
        coreutils = null;
        git = null;
      };
      required = true;
    };
    bins = let
      coreutils = "${all.records.coreutils.paths.binary}";
      inherit (all.binaries) git;
      rm = "${coreutils}/rm";
    in {
      inherit git rm;
      gitCfgFile = "${git} config --file";
      rmf = "${rm} --force";
    };
  in {inherit all bins;};

  args = {
    inherit config context defined lix user entryAfter;
    inherit (context) cfg;
    inherit (tool) bins;
  };
in
  mkConfig {
    inherit context;
    options = import ./options.nix args;
    outputs = import ./config.nix args;
  }
