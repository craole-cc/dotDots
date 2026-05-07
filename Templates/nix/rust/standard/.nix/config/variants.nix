{}: {
  baseArgs = {
    minimal = {};
    default = {includeExtras = true;};
    stable = {
      channel = "stable";
      includeExtras = true;
    };
    full = {
      includeExtras = true;
      includeWorkflow = true;
      includeWeb = true;
      includeDatabase = true;
      includeRust = true;
    };
  };
  baseDeployArgs = {
    minimal = {};
    default = {};
    stable = {};
    full = {includeWeb = true;};
  };
  editorNames = ["vscode" "helix" "zed" "rustrover" "neovim"];
  editorSuffixes = {
    vscode = "Vscode";
    helix = "Helix";
    zed = "Zed";
    rustrover = "Rustrover";
    neovim = "Neovim";
  };
}
