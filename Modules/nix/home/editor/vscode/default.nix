{
  config,
  lix,
  inputs,
  pkgs,
  host,
  user,
  paths,
  entryAfter,
  ...
}: let
  inherit (lix.applications.generators) userApplicationConfig;
  inherit (lix.attrsets.aggregation) mergeSafe;
  inherit (lix.attrsets.construction) genAttrs;
  inherit (lix.modules.construction) mkConfig mkContext mkMerge mkDefault;
  inherit (lix.options.construction) mkEnable mkFalse mkTrue;
  inherit (lix.lists.construction) optional;
  inherit (lix.lists.predicates) isIn;
  inherit (lix.schema.fonts) mkFonts;
  inherit (lix.sources.packages) pkgsFrom;
  inherit (lix.strings.construction) optionalString;

  requires = applications: isIn applications (user.applications.allowed or []);

  context = mkContext {
    inherit config;
    dom = "editor";
    mod = "vscode";
    kind = "editor";
  };
  inherit (context) cfg wantsDmsShell;

  tools = pkgsFrom {
    inherit inputs pkgs;
    sources = {
      coreutils = null;
      jaq = null;
      vscode-fhs = null;
      vscode-insiders =
        if cfg.insiders
        then "vscode-insiders"
        else null;
    };
    required = true;
  };

  bins = let
    coreutils =
      genAttrs ["chmod" "cp" "dirname" "install" "mkdir" "rm"]
      (command: "${tools.coreutils.paths.binary}/${command}");
  in
    mergeSafe [
      coreutils
      tools.binaries
      {rmf = "${coreutils.rm} -rf";}
    ];

  args = {
    inherit
      bins
      cfg
      config
      context
      entryAfter
      requires
      host
      inputs
      lix
      mkDefault
      pkgs
      paths
      tools
      mkMerge
      mkEnable
      user
      ;
    fonts = mkFonts {inherit host user;};
    json = pkgs.formats.json {};
  };

  profile = import ./settings args;
  build = import ./build (args // {profile = profile.output;});
  app = userApplicationConfig {
    inherit context user pkgs;
    name = "vscode";
    category = "gui";
    customPackage = tools.vscode-fhs.package;
    resolutionHints = [
      "code"
      "vscode"
      "vscode-fhs"
      "vscode-insiders"
    ];
    #? Correct the resolved Insiders package metadata so desktop/icon/CLI
    #? identity is Insiders rather than stable `code`.
    extraPackages = optional cfg.insiders (
      tools.vscode-insiders.package.overrideAttrs (old: {
        # Restore the original .NET bundle after fixup, as in Nixpkgs' VS Code package.
        postFixup =
          (old.postFixup or "")
          + optionalString pkgs.stdenv.hostPlatform.isLinux ''
            signer=resources/app/node_modules/@vscode/vsce-sign/bin/vsce-sign
            cp "./$signer" "$out/lib/vscode/$signer"
            patchelf --add-needed ${pkgs.openssl.out}/lib/libssl.so.3 "$out/lib/vscode/$signer"
            chmod +x "$out/lib/vscode/$signer"
          '';
        passthru =
          (old.passthru or {})
          // {
            executableName = "code-insiders";
            longName = "Visual Studio Code - Insiders";
            iconName = "vscode-insiders";
          };
      })
    );
    debug = false;
  };
in
  mkConfig {
    inherit context;
    options = mergeSafe [
      profile.options
      {
        enable = mkEnable {
          inherit context;
          condition = app.enable;
        };
        insiders = mkTrue "Whether to use Visual Studio Code Insiders instead of the standard release.";
        importJSON = mkFalse "Import fallback VS Code settings and keybindings from the saved JSON configuration.";
        dms.enable = mkEnable {
          inherit context;
          inherit (wantsDmsShell) condition;
        };
      }
    ];

    outputs = {
      home = app.home // build.activation;
    };
  }
