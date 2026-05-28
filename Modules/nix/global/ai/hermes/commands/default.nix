{
  # apps,
  description,
  dots,
  paths,
  runtimes,
  ...
}: let
  inherit (dots) lib;
  inherit (lib.attrsets) attrNames attrValues mapAttrs;
  inherit (lib.lists) concatLists;

  names = attrNames services;
  commands = mapAttrs service-builder.mkService services;

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

  aggregate = import ./aggregate.nix {
    inherit helpers lib names commands;
  };
in
  concatLists [
    (concatLists (
      map
      (svc: with svc; [start stop status help])
      (attrValues commands)
    ))
    (attrValues aggregate.all)
  ]
  ++ (with (import ./ollama.nix {
      inherit helpers runtimes service-builder;
    }); [
      ollama-models
      ollama-chat
    ])
  ++ (with (import ./hermes.nix {
      inherit helpers runtimes;
    }); [
      hermes-tui
      hermes-chat
      hermes-dev
      hermes-research
      hermes-writing
      hermes-lab
      hermes-setup
      hermes-whatsapp
    ])
  ++ [
    ((import ./help.nix {
      inherit helpers lib description names commands;
      inherit (aggregate) all;
    }).show-help)
  ]
