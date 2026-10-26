{
  stores ? {
    src = ./.;
    lib = ./Libraries/nix;
    api = ./API/nix;
  },
  ...
} @ args:
import stores.lib (args
  // {
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
      toolkit = {
        prefer = {
          kill = "procps";
          uptime = "procps";
        };
        sources = {
          #> Archives and compression
          ouch = null; #? tar, zip, gz, xz, zst, bz2, 7z, ... in one binary

          #> Core utilities
          coreutils = {discover = true;};
          moreutils = {discover = true;};
          diffutils = {
            discover = true; #? cmp, diff, diff3, sdiff
            exe = "cmp";
          };
          file = null;
          findutils = {discover = true;}; #? xargs (find is covered by fd)
          gnupatch = {exe = "patch";};
          gnused = {discover = true;};
          gnugrep = {discover = true;};
          gawk = {discover = true;};
          tree = null;

          #? Formatters
          biome = null;
          dprint = null;
          alejandra = null;

          #> Desktop and session
          dbus = {
            discover = true; #? dbus-send, dbus-monitor, ...
            exe = "dbus-send";
          };
          glib = {
            discover = true; #? gdbus, gio, gsettings, ...
            exe = "gsettings";
          };
          libnotify = {exe = "notify-send";};
          wl-clipboard = {
            discover = true; #? wl-copy, wl-paste
            exe = "wl-copy";
          };
          xdg-utils = {
            discover = true; #? xdg-open, xdg-mime, ...
            exe = "xdg-open";
          };

          #> Desktop Panels && Styling
          dms-shell = {input = "dank-material-shell";};
          quickshell = {input = "quickshell";};

          #> Editors
          vscode-fhs = null;
          vscode-insiders = {
            input = "vscode-insiders";
            exe = "code-insiders";
          };

          #> Files and viewing
          bat = null; #? cat
          dust = null; #? du
          eza = null; #? ls
          fd = null; #? find
          fzf = null;

          #> Networking
          curl = null;
          iproute2 = {
            discover = true; #? ip, ss, bridge, ...
            exe = "ip";
          };

          #> Shell and development
          bash = null;
          dash = null; #? POSIX sh, for `write.posix` shebangs
          git = null;
          gum = null;

          #> System
          procps = {
            discover = true; #? pkill, pgrep, ps, top, ...
            exe = "pkill";
          };
          systemd = {
            discover = true; #? systemctl, journalctl, ...
            exe = "systemctl";
          };
          util-linux = {
            discover = true; #? mount, lsblk, flock, logger, ...
            exe = "mount";
          };

          #> Text and data processing
          jaq = null; #? jq
          ripgrep = null; #? grep
          sd = null; #? sed
        };
      };
    };
  })
