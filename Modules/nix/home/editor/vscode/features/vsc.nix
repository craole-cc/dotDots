{lix, ...}: let
  inherit (lix.applications.editors) mkVSCodeFeature;
in
  mkVSCodeFeature {
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
  }
