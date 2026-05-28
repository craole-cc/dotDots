{
  apps,
  description,
  dots,
  paths,
  runtimes,
  ...
}: let
  inherit (dots) lib;
  inherit (lib.attrsets) attrNames attrValues mapAttrs;
  inherit (lib.lists) concatLists;

  helpers = import ./helpers.nix {
    inherit dots paths;
  };

  service-builder = import ./service-builder.nix {
    inherit dots helpers runtimes;
  };

  services = import ./services.nix {
    inherit (helpers) prepare-hermes-messaging prepare-whatsapp-bridge;
    inherit runtimes;
  };

  names = attrNames services;
  commands = mapAttrs service-builder.mkService services;

  aggregate = import ./aggregate.nix {
    inherit helpers names commands;
  };

  ollama = import ./ollama.nix {
    inherit helpers runtimes service-builder;
  };

  hermes = import ./hermes.nix {
    inherit helpers runtimes;
  };

  help = import ./help.nix {
    inherit helpers description names commands;
    inherit (aggregate) all;
  };
in
  concatLists [
    (concatLists (map (svc: [
        svc.start
        svc.stop
        svc.status
        svc.help
      ]) (attrValues commands)))
    (attrValues aggregate.all)
  ]
  ++ [
    ollama.ollama-models
    ollama.ollama-chat
    hermes.hermes-tui
    hermes.hermes-chat
    hermes.hermes-dev
    hermes.hermes-research
    hermes.hermes-writing
    hermes.hermes-lab
    hermes.hermes-setup
    hermes.hermes-whatsapp
    help.show-help
  ]
