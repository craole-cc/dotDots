{
  stores ? {
    src = ./.;
    lib = ./Libraries/nix;
    api = ./API/nix;
  },
  ...
} @ args: let
  defaults = {
    inputs = {
      config = {
        allowUnfree = true;
        allowBroken = false;
      };
      core = {
        attrs = "legacyPackages";
        names = ["nixpkgs" "nixpkgs-stable" "nixpkgs-unstable"];
      };
      home = {
        attrs = "packages";
        names = [
          "age"
          "niri-float-sticky"
          "caelestia"
          "catppuccin"
          "codex"
          "buuf-icons"
          "codex-plugins"
          "codex-skills"
          "dank-material-shell"
          "dms-plugin-registry"
          "fresh-editor"
          "helix"
          "hermes-agent"
          "home-manager"
          "llm-agents"
          "noctalia-shell"
          "nvf"
          "plasma"
          "quickshell"
          "treefmt"
          "typix"
          "vscode-insiders"
          "warp-terminal"
          "zen-browser"
        ];
      };
    };
    toolkit = let
      prefer = {
        kill = "procps";
        uptime = "procps";
      };
      sources = {
        alejandra = null; #? opinionated Nix formatter
        bash = null; #? Bourne-again shell
        bat = null; #? cat with syntax highlighting
        biome = null; #? fast formatter + linter (JS/TS/JSON/CSS)
        coreutils = {discover = true;}; #? core file, text and shell utilities
        curl = null; #? transfer data with URLs
        dash = null; #? lightweight POSIX sh (for `write.posix` shebangs)
        dbus = {
          discover = true; #? dbus-send, dbus-monitor, ...
          exe = "dbus-send";
        };
        diffutils = {
          discover = true; #? cmp, diff, diff3, sdiff
          exe = "cmp";
        };
        dms-shell = {input = "dank-material-shell";}; #? Dank Material Shell
        dprint = null; #? pluggable multi-language code formatter
        dust = null; #? intuitive du (disk usage)
        eza = null; #? modern ls replacement
        fd = null; #? simple, fast find alternative
        file = null; #? determine file type
        findutils = {discover = true;}; #? xargs (find is covered by fd)
        fzf = null; #? command-line fuzzy finder
        gawk = {discover = true;}; #? GNU awk
        gh = null; #? GitHub CLI
        git = null; #? distributed version control
        glib = {
          discover = true; #? gdbus, gio, gsettings, ...
          exe = "gsettings";
        };
        gnugrep = {discover = true;}; #? GNU grep
        gnupatch = {exe = "patch";}; #? apply diff patches
        gnused = {discover = true;}; #? GNU sed
        gum = null; #? glamorous shell script helpers
        hyprpaper = null; #? wallpaper daemon for Hyprland
        iproute2 = {
          discover = true; #? ip, ss, bridge, ...
          exe = "ip";
        };
        jaq = null; #? jq-compatible JSON processor (Rust)
        jq = null; #? command-line JSON processor
        libnotify = {exe = "notify-send";}; #? desktop notifications
        moreutils = {discover = true;}; #? additional Unix tools (sponge, parallel, ...)
        ouch = null; #? unified (de)compressor (tar, zip, 7z, gz, xz, zst, ...)
        procps = {
          discover = true; #? pkill, pgrep, ps, top, ...
          exe = "pkill";
        };
        quickshell = {input = "quickshell";}; #? QtQuick-based desktop shell
        ripgrep = null; #? fast recursive grep (rg)
        sd = null; #? intuitive sed alternative
        swaybg = null; #? wallpaper utility for Sway
        systemd = {
          discover = true; #? systemctl, journalctl, ...
          exe = "systemctl";
        };
        tree = null; #? list directory contents as a tree
        util-linux = {
          discover = true; #? mount, lsblk, flock, logger, ...
          exe = "mount";
        };
        variety = null; #? wallpaper changer with scheduling & effects
        vscode-fhs = null; #? VS Code (FHS environment)
        vscode-insiders = {
          input = "vscode-insiders";
          exe = "code-insiders";
        }; #? VS Code Insiders
        wl-clipboard = {
          discover = true; #? wl-copy, wl-paste
          exe = "wl-copy";
        };
        xdg-utils = {
          discover = true; #? xdg-open, xdg-mime, ...
          exe = "xdg-open";
        };
        yq-go = null; #? portable YAML/JSON/XML processor (Go)
      };
      groups = rec {
        archives = {inherit (sources) ouch;};
        core = {inherit (sources) coreutils moreutils diffutils file findutils gnupatch gnused gnugrep gawk tree;};
        formatters = {inherit (sources) biome dprint alejandra;};
        desktop = {inherit (sources) dbus glib libnotify wl-clipboard xdg-utils dms-shell quickshell hyprpaper swaybg variety;};
        editors = {inherit (sources) vscode-fhs vscode-insiders;};
        files = {inherit (sources) bat dust eza fd fzf;};
        networking = {inherit (sources) curl iproute2;};
        shells = {inherit (sources) bash dash gh git gum;};
        system = {inherit (sources) procps systemd util-linux;};
        text = {inherit (sources) jq yq-go jaq ripgrep sd;};
        scripting =
          core
          // files
          // shells
          // system
          // text
          // networking
          // archives
          // {inherit (sources) dbus glib libnotify wl-clipboard xdg-utils;};
        all = sources;
      };
    in {inherit groups prefer sources;};
  };
in
  import stores.lib (args // {defaults = (args.defaults or {}) // defaults;})
