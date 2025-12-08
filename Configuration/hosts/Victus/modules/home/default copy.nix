{
  inputs ? {},
  lib,
  pkgs,
  config,
  icons,
  host,
  lix,
  ...
}: let
  inherit (lib) mkIf;
  inherit (lib.attrsets) filterAttrs mapAttrs;
  inherit (lix.enums) hostFunctionalities userCapabilities;
  inherit (lix.trivial) isNotEmpty;

  hmUsers = filterAttrs (_: user: (user.role != "service")) host.users;
  mkHomeUser = name: user: let
    # TODO: move this to lix
    policies = let
      hasFun = f: hostFunctionalities.validator {name = f;};
      hasCap = c: userCapabilities.validator {name = c;};

      hasInternet = hasFun "wired" || hasFun "wireless";
      hasGui = hasFun "video";
      hasAudio = hasFun "audio";
    in {
      web = hasInternet;
      webGui = hasInternet && hasGui;
      dev = hasCap "development";
      devGui = hasCap "development" && hasGui;
      media = (hasCap "multimedia" || hasCap "creation") && hasAudio && hasGui;
      webMedia = hasInternet && hasAudio && hasGui;
      productivity = (hasCap "writing" || hasCap "analysis" || hasCap "management") && hasGui;
      gaming = hasCap "gaming" && hasGui;
    };

    # TODO: This is here only because of the infinite recursion issue
    firefox = lix.generators.firefox.mkModule {
      inherit inputs pkgs policies;
      variant = user.applications.browser.firefox or null;
    };
  in {
    _module.args = {
      user = user // {inherit name;};
      inherit policies inputs icons;
      # TODO: This is here only because of the infinite recursion issue
      inherit firefox;
    };

    home = {
      inherit (config.system) stateVersion;
      enableNixpkgsReleaseCheck = false;
    };
    programs.home-manager.enable = true;
    imports =
      [./environment ./programs ./services]
      ++ (
        # TODO: This is here only because of the infinite recursion issue
        with firefox.zen;
          if isNotEmpty module
          then [module]
          else []
      )
      ++ [];
  };
in {
  home-manager = mkIf (host != null && hmUsers != {}) {
    backupFileExtension = "backup";
    overwriteBackup = true;
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit
        lix
        host
        icons
        ;
    };
    # sharedModules = [../themes/icons];
    # users = mapAttrs mkHomeUser hmUsers;
  };
}
