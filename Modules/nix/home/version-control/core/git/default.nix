{
  config,
  entryAfter,
  lix,
  user,
  ...
}: let
  inherit (lix.modules.construction) mkContext mkConfig;

  context = mkContext {
    inherit config;
    dom = "version-control";
    sub = "core";
    mod = "git";
  };

  defined = user.git;

  args = {
    inherit config context defined lix user entryAfter;
    inherit (context) cfg;
  };
in
  mkConfig {
    inherit context;
    options = import ./options.nix args;
    outputs = import ./config.nix args;
  }
