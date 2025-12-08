{args, ...}:
with args; let
  inherit (lib.attrsets) mapAttrs hasAttrByPath;

  mkUser = name: user: let
    policies = import ./policies.nix {
      inherit lib;
      inherit (host) hostFunctionalities;
      inherit (user) userCapabilities;
    };
    firefox = import ./programs/firefox/module.nix {inherit user policies;};
  in {
    _module.args = {
      user = user // {inherit name;};
      inherit host;
    };

    home = {
      inherit (host.system) stateVersion;
      enableNixpkgsReleaseCheck = false;
    };

    programs.home-manager.enable = true;

    imports =
      [./environment ./programs ./services]
      ++ (
        if hasAttrByPath ["zen" "module"] firefox
        then [firefox.zen.module]
        else []
      );
  };
in
  mapAttrs mkUser users
