{lib, ...}: let
  inherit (lib.attrsets) attrNames listToAttrs mapAttrs;
  inherit (lib.packages) getSystem mkFmt;
  inherit (lib.shells) deployConfig mkTools;
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
    shellHook = "";
    packages = let
      formatter = fmt.packages.${getSystem pkgs};
      application = tools.packages;
      deployment = [deployConfig ({inherit pkgs;} // deployArgs)];
      extra = extraPackages;
    in
      []
      ++ formatter
      ++ application
      ++ deployment
      ++ extra;
  };

  mkEnvVariant = {
    builder,
    args,
  }:
    builder {shellArgs = args;};

  mkIdeVariant = {
    builder,
    variants,
    editors,
  }:
    listToAttrs (concatMap (variant:
      map (editor: {
        name = concatNonEmpty [
          variant
          "With"
          "${toPascalCase editor}"
        ];
        value = builder {
          shellArgs = variants.${variant};
          deployArgs = {withEditor = editor;};
        };
      })
      editors) (attrNames variants));

  mkVariants = {
    pkgs,
    inputs,
    self,
    variants,
    editors,
  }: let
    builder = mkDevShell {inherit pkgs inputs self;};
    base = mapAttrs (_: args: mkEnvVariant {inherit builder args;}) variants;
    editor = mkIdeVariant {inherit editors builder variants;};
    all = base // editor;
    raw = variants;
  in
    all // {inherit all base editor raw;};
in {inherit mkEnvVariant mkIdeVariant mkVariants;}
