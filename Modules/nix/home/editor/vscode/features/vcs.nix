{
  inputs,
  lib,
  lix,
  pkgs,
  ...
}: let
  inherit (lix.applications.editors) mkVSCodeFeature mkVSCodeSubFeature;
  inherit (lib.modules) mkMerge;
  inherit (lib.lists) flatten;

  git = mkVSCodeSubFeature {
    enabled = true;
    extensions = [
      #? .gitignore language support
      "codezombiech.gitignore"
      #? git log, file, line history
      "donjayamanne.githistory"
      #? visual git branch graph
      "mhutchie.git-graph"
      #? inline git blame
      "waderyan.gitblame"
      #? LSP for .gitconfig files
      "yy0931.gitconfig-lsp"
    ];
    userSettings = {
      "git.allowForcePush" = true;
      "git.autofetch" = true;
      "git.confirmForcePush" = false;
      "git.confirmSync" = false;
      "git.enableSmartCommit" = true;
      "git.enabled" = true;
      "git.ignoreRebaseWarning" = true;
      "git.openRepositoryInParentFolders" = "always";
      "git.rebaseWhenSync" = true;
      "gitlens.currentLine.enabled" = false;
      "gitlens.hovers.currentLine.over" = "line";
    };
  };

  jujutsu = mkVSCodeSubFeature {
    enabled = false;
    extensions = [
      #? jujutsu VCS GUI
      "visualjj.visualjj"
      #? jujutsu keybindings
      "jjk.jjk"
    ];
  };
in {
  name = "vcs";
  description = "Git, jj and version control extensions";
  default = true;
  feature = enabled:
    mkVSCodeFeature {
      inherit enabled pkgs inputs;
      extensions = flatten [
        git.extensions
        jujutsu.extensions
      ];
      userSettings = mkMerge [
        (git.userSettings or {})
        (jujutsu.userSettings or {})
      ];
    };
}
