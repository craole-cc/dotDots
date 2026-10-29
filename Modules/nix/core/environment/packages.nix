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

  interface = config.${top}.resolved.interface or {};
  session = config.interface.common.session or {};
  resolvedProtocol = interface.displayProtocol or null;
  sessionProtocol = session.protocol or null;
  displayProtocol =
    if resolvedProtocol != null
    then resolvedProtocol
    else if sessionProtocol != null
    then sessionProtocol
    else "wayland";

  user = host.users.data.primary or {};
  groups = user.packages or (lix.schema.packages.resolve {record = user;});

  registry = let
    editor = editors.packages {
      inherit pkgs system inputs;
      config = {
        tty = groups.editor or {};
        gui = groups.ide or {};
      };
    };

    browser = browsers.packages {
      inherit pkgs system inputs;
      config = groups.browser or {};
    };

    terminal = terminals.packages {
      inherit pkgs system inputs;
      config = groups.terminal or {};
    };

    launcher = launchers.packages {
      inherit pkgs system inputs;
      config = groups.launcher or {};
    };

    bar = bars.packages {
      inherit pkgs system inputs;
      config = groups.bar or {};
    };

    explorer = unique (filter (pkg: pkg != null) (
      map (
        name: let
          app = resolve {
            value = name;
            category = "explorer";
          };
        in
          resolvePackage {inherit app inputs pkgs system;}
      )
      (groups.explorer or [])
    ));

    ai = let
      tools = groups.ai-agent or [];
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
      age
      bat
      bitwarden-cli
      bitwarden-desktop
      btop
      biome #TODO: Should be gated based on need
      dprint #TODO: Should be gated based on need
      coreutils
      diffutils
      fastfetch
      fend
      figlet
      findutils
      gawk
      getent
      gitui
      gnome-randr #TODO: Is there a more universal package?
      gnused
      gum
      helix
      jaq
      yq-go
      jq
      jql
      lolcat
      lshw
      patch
      pciutils
      procs
      sops
      treefmt
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
      ripgrep
      rsync
      sad
      sd
      trashy
      udiskie
    ];

    network = with pkgs; [
      curl
      gh
      nftables
      speedtest-go
      speedtest-rs
      wget
    ];

    media = with pkgs; [
      ffmpeg-headless
      ffmpegthumbnailer
      imagemagick
      imv
      nomacs
      poppler
      qimgv
      resvg
      shortwave
      viu
      yazi
    ] ++ (filter (pkg: pkg != null) (map (name: let
      resolved = builtins.tryEval (resolve {value = name; category = "media";});
    in
      if resolved.success
      then resolvePackage {app = resolved.value; inherit inputs pkgs system;}
      else pkgs.${name} or null) (groups.media or [])));

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
  in {inherit ai bar browser common darwin dev editor explorer files launcher linux machine media network overall utils terminal wayland;};
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
      nixpkgs.overlays = [
        inputs."rust-overlay".overlays.default
      ];
      environment.systemPackages = flatten (cfg.default ++ cfg.extra);
    };
  }
