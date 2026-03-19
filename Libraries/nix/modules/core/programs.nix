{_, ...}: let
  inherit (_.lists.predicates) isIn;

  exports = {
    internal = {inherit mkPrograms;};
    external = {mkCorePrograms = mkPrograms;};
  };

  mkPrograms = {host, ...}: let
    #~@ User profile
    user = host.users.data.primary or {};

    #~@ Host interface
    wm = host.interface.windowManager    or null;
    shell = host.interface.shell  or null;
    prompt = host.interface.prompt           or null;
  in {
    programs = {
      #~@ Shell
      bash = {
        enable = isIn "bash" ([shell] ++ (user.shells or []));
        blesh.enable = true;
        undistractMe.enable = true;
      };

      direnv = {
        enable = true;
        silent = true;
        settings.global = {
          log_format = "-";
          log_filter = "^$";
          load_dotenv = true;
        };
      };

      starship.enable = prompt == "starship";

      #~@ Version control
      git = {
        enable = true;
        lfs.enable = true;
        prompt.enable = true;
      };

      #~@ Window managers
      hyprland = {
        enable = wm == "hyprland";
        withUWSM = true;
      };
      niri = {
        enable = wm == "niri";
      };

      #~@ Media
      obs-studio = {
        enable = isIn ["video" "webcam"] (host.functionalities or []);
        enableVirtualCamera = true;
      };

      #~@ Display
      xwayland = {
        enable = true;
      };
    };
  };

  exports = {inherit mkPrograms;};
in
  exports.internal // {_rootAliases = exports.external;}
