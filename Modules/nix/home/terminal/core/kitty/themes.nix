{
  context,
  lix,
  ...
}: let
  inherit (lix.modules.construction) mkDefault mkIf;
in {
  # DMS owns these files and regenerates them when the desktop theme changes.
  extraConfig = mkIf context.wantsDmsShell.condition (mkDefault ''
    include dank-tabs.conf
    include dank-theme.conf
    include dotdots-opacity.conf
    include dotdots-contrast.conf
  '');
}
