{
  cfg,
  lix,
  pkgs,
  resolve,
  entryBetween,
  ...
}: let
  inherit (lix.modules.construction) mkIf mkLayer;
  inherit (lix.options.construction) mkOption;
  inherit (lix.strings.transformation) escapeShellArg escapeShellArgs;
  inherit (lix.types.combinators) listOf;
  inherit (lix.types.primitives) str;
  python = pkgs.python3.withPackages (packages: [packages.python-dotenv]);
in {
  resolutions.credentials = mkLayer 1000 (resolve {credentials.sources = [];}).credentials;
  options.credentials.sources = mkOption {
    type = listOf str;
    default = [];
    description = "Ordered runtime dotenv paths or glob patterns. Activation merges all keys; later sources override earlier values without placing secrets in the Nix store.";
  };
  outputs.home.activation.hermesCredentials = mkIf (cfg.credentials.sources != []) (
    entryBetween ["hermesAgentSetup" "hermesProfiles"] ["writeBoundary" "linkGeneration"] ''
      $DRY_RUN_CMD ${python}/bin/python ${./merge.py} \
        ${escapeShellArg "${cfg.home.path}/credentials.env"} \
        ${escapeShellArgs cfg.credentials.sources}
    ''
  );
}
