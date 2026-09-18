{
  config,
  user,
  lix,
  ...
}: let
  inherit (lix.lists.predicates) isIn;
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;

  context = mkContext {
    inherit config;
    dom = "shells";
    sub = "core";
    mod = "powershell";
  };
  isAllowed = isIn "powershell" ((user.shells or []) ++ (user.applications.allowed or []));
in
  mkConfig {
    inherit context;
    options.enable = mkEnable {
      inherit context;
      condition = isAllowed;
    };
    outputs.home.file.".config/powershell/Microsoft.PowerShell_profile.ps1".source =
      ../../../../../../Assets/Home/profile.ps1;
  }
