{
  vars = [
    "HOME"
    "UID"
  ];

  names = {
    flake = "dots";
    repo = "https://github.com/craole-cc/dotDots.git";
    prefix = ".";
    top = "_";
    lib = "lix";
    alpha = "craole";
  };

  paths = {
    roots = {
      core.local = "";
      home.local = {var = "HOME";};
      base.local = "/";
      xdg.local = {var = "HOME";};
    };

    stems = {
      core = {
        cache = let
          default = [".cache"];
        in {
          inherit default;
          tmp = default ++ ["tmp"];
        };

        temp = let
          default = [".cache" "tmp"];
        in {
          inherit default;
        };

        api = let
          base = ["API"];
          default = base ++ ["nix"];
        in {
          inherit base default;
          nix = default;
          rs = base ++ ["rust"];
          py = base ++ ["python"];
          sh = base ++ ["bash"];
          global = default ++ ["global"];
          hosts = default ++ ["hosts"];
          users = default ++ ["users"];
        };

        cfg = let
          base = ["Configuration"];
        in {
          inherit base;
          default = base;
        };

        env = let
          base = ["Environment"];
          default = base;
        in {
          inherit default;
          nu = base ++ ["nushell"];
          sh = base ++ ["posix"];
          pwsh = base ++ ["powershell"];
        };

        kit = let
          base = ["Templates"];
          default = base ++ ["nix"];
        in {
          inherit default;
          nix = default;
          rs = base ++ ["rust"];
          sh = base ++ ["posix"];
          common = default ++ ["common"];
          dev = default ++ ["dev"];
          media = default ++ ["media"];
          full = default ++ ["full"];
        };

        lib = let
          base = ["Libraries"];
          default = base ++ ["nix"];
        in {
          inherit default;
          nix = default;
          rs = base ++ ["rust"];
          nu = base ++ ["nushell"];
          sh = base ++ ["posix"];
          pwsh = base ++ ["powershell"];
          bash = base ++ ["bash"];
          py = base ++ ["python"];
        };

        mod = let
          base = ["Modules"];
          default = base ++ ["nix"];
        in {
          inherit default;
          nix = default;
          rs = base ++ ["rust"];
          global = default ++ ["global"];
          core = default ++ ["core"];
          home = default ++ ["home"];
        };

        pkg = let
          base = ["Packages"];
          default = base ++ ["nix"];
        in {
          inherit default;
          nix = default;
          rs = base ++ ["rust"];
          global = default ++ ["global"];
          core = default ++ ["core"];
          home = default ++ ["home"];
          overlays = default ++ ["overlays"];
          plugins = default ++ ["plugins"];
        };

        sec = let
          base = ["Private"];
          default = base ++ ["nix"];
        in {
          inherit default;
          nix = default;
          rs = base ++ ["rust"];
          age = default ++ ["secrets.nix"];
          vpn = base ++ ["vpn.age"];
        };

        res = let
          base = ["Assets"];
          images = base ++ ["Images"];
          default = base;
        in {
          inherit default images;
          fonts = base ++ ["Fonts"];
          icons = base ++ ["Icons"];
          ascii = base ++ ["Ascii"];
          logos = base ++ ["Logos"];
          wallpapers = images ++ ["wallpapers"];
        };
      };

      home = {
        base = [];
        desktop = ["Desktop"];
        documents = ["Documents"];
        downloads = ["Downloads"];
        music = ["Music"];
        pictures = ["Pictures"];
        private = ["Private"];
        projects = ["Projects"];
        public = ["Public"];
        screenshots = ["Pictures" "Screenshots"];
        templates = ["Templates"];
        videos = ["Videos"];
        wallpapers = ["Pictures" "Wallpapers"];
      };

      base = {
        bin = let default = ["bin"]; in {inherit default;};
        boot = let default = ["boot"]; in {inherit default;};
        dev = let default = ["dev"]; in {inherit default;};
        etc = let default = ["etc"]; in {inherit default;};
        lib = let default = ["lib"]; in {inherit default;};
        media = let default = ["media"]; in {inherit default;};
        mnt = let default = ["mnt"]; in {inherit default;};
        nix = let
          base = ["nix"];
          default = base;
        in {
          inherit default;
          store = base ++ ["store"];
          var = base ++ ["var"];
        };
        opt = let default = ["opt"]; in {inherit default;};
        proc = let default = ["proc"]; in {inherit default;};
        root = let default = ["root"]; in {inherit default;};
        run = let default = ["run"]; in {inherit default;};
        sbin = let default = ["sbin"]; in {inherit default;};
        srv = let default = ["srv"]; in {inherit default;};
        sys = let default = ["sys"]; in {inherit default;};
        tmp = let default = ["tmp"]; in {inherit default;};
        usr = let
          base = ["usr"];
          default = base;
        in {
          inherit default;
          bin = base ++ ["bin"];
          lib = base ++ ["lib"];
          local = base ++ ["local"];
          sbin = base ++ ["sbin"];
          share = base ++ ["share"];
        };
        var = let
          base = ["var"];
          default = base;
        in {
          inherit default;
          cache = base ++ ["cache"];
          lib = base ++ ["lib"];
          lock = base ++ ["lock"];
          log = base ++ ["log"];
          run = base ++ ["run"];
          spool = base ++ ["spool"];
          tmp = base ++ ["tmp"];
        };
      };

      xdg = {
        config = [".config"];
        data = [".local" "share"];
        cache = [".cache"];
        state = [".local" "state"];
        bin = [".local" "bin"];
        runtime = ["/run" "user" {var = "UID";}];
      };
    };
  };

  environment = {
    # ~@ General
    # HOME = "/home/${USER}";
    LANG = "en_US.UTF-8";
    TIME = "UTC";

    # ~@ Applications
    SHELL = "/bin/bash";
    EDITOR = "hx";
    VISUAL = "code";
    PAGER = "less";
    BROWSER = "firefox";
    TERMINAL = "ghostty";

    # ~@ Common
    LOCALHOST = "127.0.0.1";
    NIXPKGS_ALLOW_UNFREE = "1";
  };
}
