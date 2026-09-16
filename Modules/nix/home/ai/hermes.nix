{
  config,
  lix,
  system,
  inputs,
  host,
  pkgs,
  ...
}: let
  inherit (lix.attrsets.access) attrValues;
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;
  inherit (lix.lists.predicates) isIn;

  context = mkContext {
    inherit config;
    dom = "ai";
    sub = "agents";
    mod = "hermes";
  };
  # inherit (context) ctx mod;
  # isAllowed = isIn mod (host.functionalities or []);
  isAllowed = true;
in
  mkConfig {
    inherit context;
    options.enable = mkEnable {
      inherit context;
      condition = isAllowed;
    };
    outputs = {
      home.packages = attrValues inputs.hermes-agent.packages.${system};
      #         nix-repl> inputs.hermes-agent.packages.${system}
      # {
      #   configKeys = «derivation /nix/store/42ii9y4skyqr6pwk1azhis0rhfi4jpjm-hermes-config-keys.drv»;
      #   default = «derivation /nix/store/wgr57bi16av7db2z5dnag4h1v2vg9gwi-hermes-agent-0.21.3.drv»;
      #   desktop = «derivation /nix/store/x0azw972x6gyq9xx2mx8akgmbxdgkiny-hermes-desktop-0.17.3.drv»;
      #   messaging = «derivation /nix/store/ids7jylg8870zkmzwdbp6zlr8xhvmp07-hermes-agent-0.21.3.drv»;
      #   minimal = ^[[A«derivation /nix/store/bj7cmfj3jsw47pg9ai6jqvvw4wizm8cv-hermes-agent-0.21.3.drv»;
      #   node-gyp = «derivation /nix/store/py7hl6i5x7mdhhvl3fwx6gdsf654wqzn-node-gyp-11.4.0.drv»;
      #   sandbox = «derivation /nix/store/82g2lsv50grzqa95jr5wyhs8hvsjbwv8-sandbox.drv»;
      #   tui = «derivation /nix/store/49kk1ny45mh8q93jf2f6bpgssxvind2n-hermes-tui-0.0.1.drv»;
      #   update-npm-lockfile = «derivation /nix/store/x2q60hykh8r9mh0zg8afbr9qp8s2i9i5-update-npm-lockfile.drv»;
      #   web = «derivation /nix/store/qrprzb9kbidpi02cm75qvipwfiml9r46-web-0.0.0.drv»;
      # }
    };
  }
