{
  lix,
  host,
  ...
}: let
  inherit (lix.trivial) boolToOneZero;
in {
  environment.sessionVariables = {
    NIXPKGS_ALLOW_UNFREE = boolToOneZero host.packages.allowUnfree;
  };
}
