{lib, ...}: let
  inherit (lib.attrsets) attrNames listToAttrs mapAttrs;
  inherit (lib.lists) concatMap;
  inherit (lib.shells) mkFmt mkSuite;

  mkVariant = {
    pkgs,
    inputs,
    self,
  }: {
    shellArgs ? {},
    deployArgs ? {},
  }:
    mkSuite {
      inherit pkgs;
      fmt = mkFmt {inherit inputs self;} shellArgs;
    } {inherit shellArgs deployArgs;};

  mkEnvVariant = {
    variant,
    args,
  }:
    variant {shellArgs = args;};

  mkIdeVariant = {
    variant,
    base,
    suffixes,
    names,
  }:
    listToAttrs (
      concatMap (
        baseName:
          map (
            editorName: {
              name = "${baseName}With${suffixes.${editorName}}";
              value = variant {
                shellArgs = base.${baseName};
                deployArgs = {withEditor = editorName;};
              };
            }
          )
          names
      )
      (attrNames base)
    );

  mkVariants = {
    pkgs,
    inputs,
    self,
    variants ? {
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
    },
  }: let
    variant = mkVariant {inherit pkgs inputs self;};

    base = mapAttrs (_: args:
      mkEnvVariant {
        inherit variant args;
      })
    variants;

    editor = mkIdeVariant {
      inherit variant;
      base = variants;
      names = ["vscode" "helix" "zed" "rustrover" "neovim"];
      suffixes = {
        vscode = "Vscode";
        helix = "Helix";
        zed = "Zed";
        rustrover = "Rustrover";
        neovim = "Neovim";
      };
    };

    all = base // editor;
  in {inherit all base editor;};
in {inherit mkVariant mkEnvVariant mkIdeVariant mkVariants;}
