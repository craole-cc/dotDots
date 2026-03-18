{
  lix,
  pkgs,
  inputs,
  ...
}: let
  inherit (lix.applications.editors) mkVSCodeFeature;
in {
  name = "vcs";
  description = "Git, jj and version control extensions";
  default = false;
  feature = enabled:
    mkVSCodeFeature {
      inherit enabled pkgs inputs;
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
        #? jujutsu VCS GUI
        "visualjj.visualjj"
        #? jujutsu keybindings
        "jjk.jjk"
      ];
    };
}
