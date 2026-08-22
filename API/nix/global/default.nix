{
  version = "2.0.0";

  names = {
    flake = "dots";
    repo = "https://github.com/craole-cc/dotDots.git";
    prefix = ".";
    top = "_";
    lib = "lix";
    alpha = "craole";
  };

  paths = {
    flake = "/home/craole/.dots";
    home = "/home/craole";
    tmpdir = "/tmp";

    cache = let
      default = [".cache"];
    in {
      inherit default;
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

    user = {
      home = [];
      documents = ["Documents"];
      downloads = ["Downloads"];
      music = ["Music"];
      pictures = ["Pictures"];
      videos = ["Videos"];
      projects = ["Projects"];
      wallpapers = [
        "Pictures"
        "Wallpapers"
      ];
      screenshots = [
        "Pictures"
        "Screenshots"
      ];
      desktop = ["Desktop"];
      public = ["Public"];
      templates = ["Templates"];
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
      runtime_dir = "/run/user/1000";
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
