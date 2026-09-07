{
  exclusions = {
    directories = [
      "review"
      "archive"
      "internal"
      "imports"
      "data"
      "test"
      "tmp"
      "temp"
      "wip"
      "deprecated"
      "experimental"
      "backup"
    ];

    files = [
      "default.nix"
      "flake.nix"
    ];

    patterns = [
      " copy.nix"
      ".test.nix"
      ".spec.nix"
      ".bak.nix"
      ".old.nix"
    ];
  };

  roots = {
    repo = "";
    home = {
      store = null;
      local = {var = "HOME";};
    };
    slash = {
      store = null;
      local = "/";
    };
    xdg = {
      store = null;
      local = {var = "HOME";};
    };
  };

  stems = {
    repo = {
      src = [];

      cache = let
        base = [".cache"];
        default = base ++ ["nix"];
      in {
        inherit base default;
        nix = default;
        tmp = default ++ ["tmp"];
      };

      temp = let
        default = [
          ".cache"
          "tmp"
        ];
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
        options = default ++ ["options"];
        paths = default ++ ["paths"];
        shells = default ++ ["shells"];
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
      screenshots = [
        "Pictures"
        "Screenshots"
      ];
      templates = ["Templates"];
      videos = ["Videos"];
      wallpapers = [
        "Pictures"
        "Wallpapers"
      ];
    };

    slash = {
      bin.default = ["bin"];
      boot.default = ["boot"];
      dev.default = ["dev"];
      etc.default = ["etc"];
      lib.default = ["lib"];
      media.default = ["media"];
      mnt.default = ["mnt"];

      nix = let
        base = ["nix"];
        default = base;
      in {
        inherit default;
        store = base ++ ["store"];
        var = base ++ ["var"];
      };

      opt.default = ["opt"];
      proc.default = ["proc"];
      root.default = ["root"];
      run.default = ["run"];
      sbin.default = ["sbin"];
      srv.default = ["srv"];
      sys.default = ["sys"];
      tmp.default = ["tmp"];

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
      data = [
        ".local"
        "share"
      ];
      cache = [".cache"];
      state = [
        ".local"
        "state"
      ];
      bin = [
        ".local"
        "bin"
      ];
      runtime = [
        "/run"
        "user"
        {var = "UID";}
      ];
    };
  };
}
