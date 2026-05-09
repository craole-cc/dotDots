{lib}: let
  inherit (lib.attrsets) attrNames attrValues listToAttrs mapAttrs;
  inherit (lib.packages) getSystem;
  inherit (lib.shells) mkTools mkFmt mkChecks;
  inherit (lib.templates) deployConfig;
  inherit (lib.lists) concatMap;
  inherit (lib.strings) concatNonEmpty toPascalCase;

  mkVariant = {
    pkgs,
    inputs,
    self,
  }: {
    shellArgs ? {},
    deployArgs ? {},
    extraPackages ? [],
    ...
  }: let
    tools = mkTools ({inherit pkgs;} // shellArgs);
    fmt = mkFmt {inherit inputs self;} shellArgs;
  in {
    inherit fmt;
    checks = fmt.checks;
    shell = {
      shellHook = "";
      packages =
        []
        ++ (attrValues fmt.packages.${getSystem pkgs})
        ++ tools.packages
        ++ [deployConfig ({inherit pkgs;} // deployArgs)]
        ++ extraPackages;
    };
  };

  mkEnvVariant = {
    builder,
    args,
  }:
    builder {shellArgs = args;};

  mkIdeVariant = {
    pkgs,
    inputs,
    self,
    variants,
    editors,
  }:
    listToAttrs (concatMap (variant:
      map (editor: {
        name = concatNonEmpty "" [variant "With" (toPascalCase editor)];
        value = mkVariant {inherit pkgs inputs self;} {
          shellArgs = variants.${variant};
          deployArgs = {withEditor = editor;};
        };
      })
      editors)
    (attrNames variants));

  mkVariants = {
    pkgs,
    inputs,
    self,
    variants,
    editors,
  }: let
    builder = mkVariant {inherit pkgs inputs self;};
    base = mapAttrs (_: args: builder {shellArgs = args;}) variants;
    editor = mkIdeVariant {inherit pkgs inputs self variants editors;};
  in {
    inherit base editor;
    raw = variants;
    shells = mapAttrs (_: v: v.shell) base // editor;
    fmts = mapAttrs (_: v: v.fmt) base;
    checks = mkChecks {
      inherit inputs;
      variants = base;
    };
  };
in {
  inherit
    mkEnvVariant
    mkIdeVariant
    mkVariant
    mkVariants
    ;
}
