{lib}: let
  combined = mergeNamespaces {inherit rust ai;};
  inherit (lib.packages) mkFmt mkChecks;
  inherit (lib.shells) ai mergeNamespaces mkShells mkVariants rust;

  mkEnvironment = {
    inputs,
    pkgs,
    self,
  }: let
    variants = mkVariants {
      inherit pkgs inputs self;
      raw = {
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
    namespaced = combined.mkDevShell {inherit pkgs;};
  in {
    devShells = mkShells {
      inherit inputs;
      default = variants.minimal;
      shells = namespaced // variants;
    };
    checks = mkChecks {
      bases = variants.raw;
      mkFmt = mkFmt {inherit inputs self;};
    };
    fmt = mkFmt variants.raw.default;
  };
in {inherit mkEnvironment;}
