{
  firefox,
  lib,
  lix,
  icons,
  host,
  user,
  config,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lix.debug) trace;
  inherit (lix.trivial) isNotEmpty;
  inherit
    (firefox)
    exists
    program
    package
    zen
    variant
    ;
  inherit (lix.generators.firefox) mkExtensionSettings mkExtensionEntry mkLockedAttrs;

  isZen = isNotEmpty zen.module;

  cfg =
    if exists
    then config.programs.${program} or {}
    else {};

  paths = let
    homeDir = config.home.homeDirectory;
  in {
    #TODO: create a function to check if a path is relative or absolute. if relative resolve from the user's home
    downloads =
      if isNotEmpty user.paths.downloads
      then "${homeDir}/${user.paths.downloads}"
      else "${homeDir}/Downloads";
  };

  debug = trace "firefox" {inherit exists program package variant isZen;};
in {
  home.sessionVariables.${debug.key} = debug.val;

  programs.${program} = mkIf exists {
    enable = true;
    package = mkIf (isNotEmpty package) package;
    profiles.default =
      import ./bookmarks.nix
      // import ./search.nix {inherit icons host;}
      // import ./settings.nix {inherit program;};

    policies =
      import ./policies.nix {inherit paths;}
      // import ./extensions.nix {inherit mkExtensionSettings mkExtensionEntry;}
      // import ./preferences.nix {inherit mkLockedAttrs;};
  };

  xdg = mkIf cfg.enable {
    mimeApps = import ./mime.nix {
      inherit lib;
      command = cfg.wrappedPackageName or program;
    };
  };
}
