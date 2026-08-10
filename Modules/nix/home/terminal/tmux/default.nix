{
  config,
  lib,
  lix,
  top,
  ...
}: let
  inherit (lix.modules.core.staging) mkStaged;
  payload = {
    programs.tmux =
      {
        enable = config.${top}.inputs.applications.utilities.tmux.enable;
      }
      # // import ./settings.nix
      // import ./plugins.nix;
  };
in {
  config = lib.mkMerge (mkStaged {
    inherit top payload;
  });
}
