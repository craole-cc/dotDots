{lib}: let
  inherit (lib.packages) mkFmt mkChecks;
  inherit (lib.shells) ai mergeNamespaces mkShells mkVariants rust;
  # inherit (mergeNamespaces {inherit rust ai;}) mkDevShell;

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
  in {
    devShells = mkShells {
      inherit inputs;
      default = variants.minimal;
      # shells = mkDevShell {inherit pkgs;} // variants;
      shells = variants;
    };
    checks = mkChecks {
      bases = variants.raw;
      mkFmt = mkFmt {inherit inputs self;};
    };
    fmt = mkFmt variants.raw.default;
  };
in {inherit mkEnvironment;}
