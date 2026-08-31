{
  lix,
  config,
  ...
}: let
  inherit (lix.filesystem.traversal) importAllPaths;
  vars = config.home.sessionVariables;
  EDITOR = vars.EDITOR_PRI or vars.EDITOR_SEC or "nano";
  EDITOR_NAME = vars.EDITOR_PRI_NAME or vars.EDITOR_SEC_NAME or "nano";
  VISUAL = vars.VISUAL_PRI or vars.VISUAL_SEC or EDITOR;
  VISUAL_NAME = vars.VISUAL_PRI_NAME or vars.VISUAL_SEC_NAME or EDITOR;
in {
  imports = (importAllPaths ./.).value;
  home.sessionVariables = {
    inherit
      EDITOR
      EDITOR_NAME
      VISUAL
      VISUAL_NAME
      ;
  };
}
