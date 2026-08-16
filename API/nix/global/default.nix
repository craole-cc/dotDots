{
  version = "2.0.0";

  names = {
    src = "dots";
    repo = "https://github.com/craole-cc/dotDots.git";
    prefix = ".";
    top = "_";
    lib = "lix";
    alpha = "craole";
    cache = ".cache";
  };

  paths = {
    src = "/home/craole/.dots";

    # API
    api = rec {
      base = ["API"];
      nix = base ++ ["nix"];
      rs = base ++ ["rust"];
      py = base ++ ["python"];
      sh = base ++ ["bash"];

      default = nix;
      global = nix ++ ["global"];
      hosts = nix ++ ["hosts"];
      users = nix ++ ["users"];
    };

    # Configuration & Environment
    cfg = rec {
      base = ["Configuration"];
      default = base;
    };
    env = rec {
      base = ["Environment"];
      nu = base ++ ["nushell"];
      sh = base ++ ["posix"];
      pwsh = base ++ ["powershell"];

      default = base;
    };

    # Kits / Templates
    kit = rec {
      base = ["Templates"];
      nix = base ++ ["nix"];
      rs = base ++ ["rust"];
      sh = base ++ ["posix"];

      default = nix;
      common = nix ++ ["common"];
      dev = nix ++ ["dev"];
      media = nix ++ ["media"];
      full = nix ++ ["full"];
    };

    # Libraries
    lib = rec {
      base = ["Libraries"];
      nix = base ++ ["nix"];
      rs = base ++ ["rust"];
      nu = base ++ ["nushell"];
      sh = base ++ ["posix"];
      pwsh = base ++ ["powershell"];
      bash = base ++ ["bash"];
      py = base ++ ["python"];

      default = nix;
    };

    # Modules
    mod = rec {
      base = ["Modules"];
      nix = base ++ ["nix"];
      rs = base ++ ["rust"];

      default = nix;
      global = nix ++ ["global"];
      core = nix ++ ["core"];
      home = nix ++ ["home"];
    };

    # Packages
    pkg = rec {
      base = ["Packages"];
      nix = base ++ ["nix"];
      rs = base ++ ["rust"];

      default = nix;
      global = nix ++ ["global"];
      core = nix ++ ["core"];
      home = nix ++ ["home"];

      overlays = nix ++ ["overlays"];
      plugins = nix ++ ["plugins"];
    };

    # Private / Secrets
    sec = rec {
      base = ["Private"];
      nix = base ++ ["nix"];
      rs = base ++ ["rust"];

      default = nix;
      age = nix ++ ["secrets.nix"];
      vpn = base ++ ["vpn.age"];
    };

    # Resources & Assets
    res = rec {
      base = ["Assets"];

      images = base ++ ["Images"];
      fonts = base ++ ["Fonts"];
      icons = base ++ ["Icons"];
      ascii = base ++ ["Ascii"];
      logos = base ++ ["Logos"];
      wallpapers = images ++ ["wallpapers"];

      default = base;
    };
  };

  environment = {
    SHELL = "/bin/bash";

    XDG_CONFIG_HOME = "\${HOME}/.config";
    XDG_DATA_HOME = "\${HOME}/.local/share";
    XDG_CACHE_HOME = "\${HOME}/.cache";
    XDG_STATE_HOME = "\${HOME}/.local/state";
    XDG_BIN_HOME = "\${HOME}/.local/bin";
    XDG_RUNTIME_DIR = "/run/user/1000";

    HOSTNAME = "localhost";
    HOST = "127.0.0.1";
    PORT = "8080";

    BINIT_ACTION = "--run";
    NIXPKGS_ALLOW_UNFREE = "1";

    EDITOR = "hx";
    VISUAL = "code";
    PAGER = "less";
    BROWSER = "firefox";
    TERMINAL = "ghostty";

    TMPDIR = "/tmp";
    LANG = "en_US.UTF-8";
    TZ = "UTC";
  };
}
