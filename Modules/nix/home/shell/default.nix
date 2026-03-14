{
  host,
  # lib,
  lix,
  pkgs,
  user,
  ...
}: let
  inherit (lix.attrsets.resolution) package;
  inherit (lix.filesystem.importers) importAll;
in {
  home = {
    inherit (host) stateVersion;
    packages = map (shell:
      package {
        inherit pkgs;
        target = shell;
      })
    (user.shells or []);
  };

  imports = importAll ./.;
}
