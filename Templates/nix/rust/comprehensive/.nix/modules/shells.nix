{lib}: let
  inherit (lib.attrsets) attrValues;
  inherit (lib.modules) mkModules;
  inherit (lib.strings) toJSON toLines;

  mkDevShell = {
    inputs,
    pkgs,
    variant,
    raw ? null,
    extraPackages ? [],
    extraEnv ? {},
    extraShellHook ? "",
  }: let
    resolved = mkModules {inherit inputs pkgs variant;};
  in {
    packages = (attrValues resolved.packages) ++ extraPackages;

    env =
      resolved.variables
      // extraEnv
      // {
        DEVSHELL_NAME = variant.__variantName or "devshell";
        DEVSHELL = toJSON variant;
        DEVSHELL_RAW = toJSON (
          if raw != null
          then raw
          else variant
        );
      };

    shellHook = toLines [
      (resolved.shellHook or null)
      extraShellHook
    ];
  };
in {  inherit mkDevShell; }
