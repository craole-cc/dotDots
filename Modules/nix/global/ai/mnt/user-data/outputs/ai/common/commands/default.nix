{
  description,
  dots,
  env,
  paths,
  runtimes,
  ...
}: let
  inherit (dots) lix lib;
  inherit (lix.filesystem.traversal) importAllNamed;
  inherit (lib.attrsets) attrNames attrValues mapAttrs filterAttrs recursiveUpdate;
  inherit (lib.lists) concatLists concatMap foldl';

  helpers = import ./helpers.nix {inherit dots paths;};

  service-builder = import ./service-builder.nix {
    inherit dots helpers runtimes;
  };

  cmds = {inherit helpers runtimes service-builder;};

  #> Every folder under ../../agents with a default.nix, keyed by folder
  #> name. Each is called with {env; cmds;} and returns
  #> {env?; packages?; commands: {service?; extra?;};} - adding a new
  #> agent means adding a folder, nothing here changes.
  agents = importAllNamed {
    args = {inherit env cmds;};
    dir = ../../agents;
  };

  #> Agents that expose a `service` (start/stop/status/help via mkService)
  serviced = filterAttrs (_: a: a.commands ? service) agents;
  names = attrNames serviced;
  commands = mapAttrs (name: a: service-builder.mkService name a.commands.service) serviced;

  aggregate = import ./aggregate.nix {
    inherit helpers lib names commands;
  };

  #> Every agent's standalone (non-serviced) bins, flattened
  extraCommands = concatMap (a: attrValues (a.commands.extra or {})) (attrValues agents);

  #> Every agent's own extra packages (e.g. hermes's telegram pythonPkgs), flattened
  extraPackages = concatMap (a: a.packages or []) (attrValues agents);

  mergedEnv = foldl' recursiveUpdate {} (map (a: a.env or {}) (attrValues agents));
in {
  inherit mergedEnv;

  packages =
    concatLists [
      (concatLists (
        map
        (svc: with svc; [start stop status help])
        (attrValues commands)
      ))
      (attrValues aggregate.all)
      extraCommands
      extraPackages
    ]
    ++ [
      (import ./help.nix {
        inherit helpers lib description names commands;
        inherit (aggregate) all;
      }).show-help
    ];
}
