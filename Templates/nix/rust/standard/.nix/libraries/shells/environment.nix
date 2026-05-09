{lib}: let
  inherit (lib.shells) ai mergeNamespaces mkShells mkVariants rust;

  mkEnvironment = {
    inputs,
    pkgs,
    self,
  }: let
    variants = mkVariants {
      inherit pkgs inputs self;
      variants = {
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
      editors = [
        "helix"
        "emacs"
        "neovim"
        "rust-rover"
        "sublime-text"
        "vscode"
        "vscode-insiders"
        "zed"
      ];
    };
    # namespaced = (mergeNamespaces {inherit rust ai;}).mkDevShell {inherit pkgs;};
  in {
    devShells = mkShells {
      inherit inputs;
      default = variants.shells.minimal;
      # shells = namespaced // variants.shells;
      inherit (variants) shells;
    };
    checks = variants.checks;
    fmt = variants.fmts.default;
  };
in {inherit mkEnvironment;}
