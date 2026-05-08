{lib, ...}: let
  inherit (lib.attrsets) attrNames listToAttrs mapAttrs;
  inherit (lib.lists) concatMap;
  inherit (lib.shells) mkFmt mkSuite;
  inherit (lib.strings) concatNonEmpty toPascal;
  inherit (lib.trivial) isNotEmpty;

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
    suffixes ? {},
    names,
  }: let
    suffixes' =
      if isNotEmpty
      then suffixes
      else
        listToAttrs (
          map (name: {
            name = name;
            value = toPascal name;
          })
          names
        );
  in
    listToAttrs (
      concatMap (
        baseName:
          map (
            editorName: {
              # name = "${baseName}With${suffixes'.${editorName}}";
              name = concatNonEmpty {parts = [baseName "With" suffixes'.${editorName}];};
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
    raw ? {
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

    base =
      mapAttrs
      (_: args: mkEnvVariant {inherit variant args;})
      raw;

    editor = mkIdeVariant {
      inherit variant;
      base = raw;
      names = [
        "helix"
        "neovim"
        "rust-rover"
        "vscode"
        "zed"
      ];
    };

    all = base // editor;
  in
    all // {inherit all base editor raw;};
in {inherit mkVariant mkEnvVariant mkIdeVariant mkVariants;}
