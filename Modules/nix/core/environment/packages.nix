{
  config,
  lix,
  host,
  inputs,
  pkgs,
  top,
  ...
}: let
  dom = "environment";
  mod = "packages";

  inherit (lix.applications.registry) resolve;
  inherit (lix.applications.resolution) bars browsers editors launchers terminals;
  inherit (lix.applications.runtime) resolvePackage;
  inherit (lix.lists.construction) optionals;
  inherit (lix.lists.selection) filter;
  inherit (lix.lists.transformation) flatten unique;
  inherit (lix.modules.construction) mkConfig mkContext mkIf;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.types.combinators) listOf;
  inherit (lix.types.primitives) package;
  inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux system;

  context = mkContext {inherit config dom mod top;};
  inherit (context) cfg ice;

  user = host.users.data.primary or {};
  apps = user.applications or {};
  displayProtocol = ice.displayProtocol or null;

  registry = let
    editor = editors.packages {
      inherit pkgs system inputs;
      config = apps.editor or {};
    };

    browser = browsers.packages {
      inherit pkgs system inputs;
      config = apps.browser or {};
    };

    terminal = terminals.packages {
      inherit pkgs system inputs;
      config = apps.terminal or {};
    };

    launcher = launchers.packages {
      inherit pkgs system inputs;
      config = apps.launcher or {};
    };

    bar = bars.packages {
      inherit pkgs system inputs;
      config = apps.bar or {};
    };

    explorer = unique (filter (pkg: pkg != null) (
      map (
        name: let
          app = resolve {
            value = name;
            category = "explorer";
          };
        in
          resolvePackage {
            inherit app inputs pkgs system;
          }
      )
      (filter (name: name != null) [
        (apps.explorer.primary or null)
        (apps.explorer.secondary or null)
        (apps.explorer.tertiary or null)
      ])
    ));

    ai = let
      tools = ["chatgpt" "hermes-desktop" "claude-desktop"];
    in
      optionals isLinux (unique (filter (pkg: pkg != null) (
        map (
          name: let
            app = resolve {
              value = name;
              category = "ai";
            };
          in
            resolvePackage {inherit app inputs pkgs system;}
        )
        tools
      )));

    #~@ Languages & Development
    dev = let
      Nix = with pkgs; [
        alejandra
        cachix
        lorri
        nil
        nix-diff
        nix-index
        nix-info
        nix-output-monitor
        nix-prefetch
        nix-prefetch-docker
        nix-prefetch-github
        nix-prefetch-scripts
        nixd
        nixfmt
        nvfetcher
        statix
      ];

      Python = with pkgs; [
        python3Minimal
        ruff
      ];

      Rust = with pkgs; [
        (rust-bin.selectLatestNightlyWith (toolchain:
          toolchain.default.override {
            extensions = [
              "clippy"
              "rust-analyzer"
              "rust-src"
              "rustfmt"
            ];
          }))
      ];

      Shellscript = with pkgs; [
        shellcheck
        shfmt
      ];

      Nushell =
        (with pkgs; [
          nushell
          nu-lint
          nufmt
        ])
        ++ (with pkgs.nushellPlugins; [
          # net #? Broken
          polars
          gstat
          # units #? Broken
          skim
          query
          formats
          # highlight #? Broken
          desktop_notifications
        ]);

      PowerShell = with pkgs; [
        powershell
        powershell-editor-services
      ];

      Zig = with pkgs; [
        zig
        zls
        ziglint
      ];
    in
      flatten [
        Nix
        Nushell
        PowerShell
        Python
        Rust
        Shellscript
        Zig
      ];

    #~@ System & Utilities
    utils = with pkgs; [
      bat
      dprint
      gitui
      gum
      helix
      jq
      jql
      patch
      ripgrep
      treefmt
      btop
      coreutils
      diffutils
      fastfetch
      fend
      figlet
      findutils
      gawk
      getent
      gnome-randr
      gnused
      lolcat
      lshw
      pciutils
      procs
      usbutils
      uutils-coreutils-noprefix
      wlr-randr
    ];

    files = with pkgs; [
      dua
      dust
      eza
      fd
      file
      fzf
      lsd
      ouch
      p7zip
      rsync
      sad
      trashy
      udiskie
    ];

    network = with pkgs; [
      curl
      wget
      gh
    ];

    media = with pkgs; [
      shortwave
      imagemagick
      imv
      nomacs
      qimgv
      viu
    ];

    #~@ Platform Helpers
    wayland = optionals (displayProtocol == "wayland") (with pkgs; [
      wl-clipboard
    ]);
    linux = optionals isLinux (with pkgs; [
      bubblewrap
      xsel
    ]);
    darwin = optionals isDarwin (with pkgs; [pngpaste]);

    common = editor ++ browser ++ terminal ++ explorer ++ launcher ++ bar ++ ai;
    machine = wayland ++ linux ++ darwin;
    overall = utils ++ dev ++ files ++ network ++ media ++ common ++ machine;
  in {
    inherit
      ai
      bar
      browser
      common
      darwin
      dev
      editor
      explorer
      files
      launcher
      linux
      machine
      media
      network
      overall
      utils
      terminal
      wayland
      ;
  };
in
  mkConfig {
    inherit context;

    options = {
      enable = mkEnable {inherit context;};

      default = mkOption {
        description = "Base system packages";
        default = registry.overall;
        type = listOf package;
      };

      extra = mkOption {
        description = "Additional packages to install";
        default = [];
        type = listOf package;
      };
    };

    outputs = mkIf cfg.enable {
      nixpkgs.overlays = [inputs."rust-overlay".overlays.default];
      environment.systemPackages = flatten (cfg.default ++ cfg.extra);
    };
  }
