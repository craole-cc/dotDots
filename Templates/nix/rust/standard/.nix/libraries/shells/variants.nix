{lib}: let
  inherit (lib.attrsets) attrNames attrValues listToAttrs mapAttrs;
  inherit (lib.packages) getSystem ;
  inherit (lib.shells) deployConfig mkTools mkFmt mkChecks;
  inherit (lib.lists) concatMap;
  inherit (lib.strings) concatNonEmpty toPascalCase;

  mkDevShell = {
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
    shellHook = "";
    packages =
      tools.packages
      ++ (attrValues fmt.packages.${getSystem pkgs})
      ++ [deployConfig ({inherit pkgs;} // deployArgs)]
      ++ extraPackages;
  };

  mkEnvVariant = {
    builder,
    args,
  }:
    builder {shellArgs = args;};

  mkVariant = {
    pkgs,
    inputs,
    self,
    args,
  }: let
    fmt = mkFmt {inherit inputs self;} args;
    shell = mkDevShell {inherit pkgs inputs self;} {shellArgs = args;};
  in {
    inherit shell fmt;
    checks = fmt.checks;
  };

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
        value = mkDevShell {inherit pkgs inputs self;} {
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
    base = mapAttrs (_: args: mkVariant {inherit pkgs inputs self args;}) variants;
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
    mkDevShell
    mkEnvVariant
    mkIdeVariant
    mkVariant
    mkVariants
    ;
}
