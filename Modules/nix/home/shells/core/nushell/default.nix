{
  config,
  lib,
  lix,
  paths,
  pkgs,
  user,
  ...
}: let
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;
  inherit (lib.modules) mkMerge;
  inherit (lix.lists.predicates) isIn;

  context = mkContext {
    inherit config;
    dom = "shells";
    sub = "core";
    mod = "nushell";
  };
  isAllowed = isIn "nushell" ((user.shells or []) ++ (user.applications.allowed or []));
  nuSection = lib.concatMapStringsSep "\n" (line: lib.removePrefix "#nu " line) (
    lib.filter (line: lib.hasPrefix "#nu " line) (
      lib.splitString "\n" (builtins.readFile ../../../../../../.dotsrc)
    )
  );
in
  mkConfig {
    inherit context;
    options.enable = mkEnable {
      inherit context;
      condition = isAllowed;
    };
    outputs = {
      programs.nushell = mkMerge [
        {
          enable = true;
          extraEnv = ''
            $env.DOTS = ($env.DOTS? | default "${paths.repo.src.local}")
            $env.DOTS_RC = ($env.DOTS | path join ".dotsrc")
          '';
          extraConfig =
            nuSection
            + "\n"
            + lib.concatMapStringsSep "\n" (name: ''
              def ${name} [...args] { ^${paths.repo.lib.nu.local}/${name}.nu ...$args }
            '') (
              map (name: lib.removeSuffix ".nu" name) (
                lib.filter (name: lib.hasSuffix ".nu" name) (
                  lib.attrNames (builtins.readDir paths.repo.lib.nu.store)
                )
              )
            );
        }
        # (import ./plugins.nix {inherit pkgs;})
        (import ./settings.nix)
      ];
      home.packages = with pkgs; [
        nufmt
        nu_scripts
      ];
    };
  }
