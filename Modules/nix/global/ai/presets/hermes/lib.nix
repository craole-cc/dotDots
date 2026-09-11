{
  name,
  components,
  cfg,
  lix,
  paths,
  init ? "",
  start ? "",
}: let
  inherit (lix.lists.aggregation) foldl';
  inherit (lix.lists.construction) concatLists;
  inherit (lix.strings.construction) concatStringsSep;

  env = foldl' (acc: component: acc // (component.env or {})) {} components;
  packages = concatLists (map (component: component.packages or []) components);
  hooks = concatStringsSep "\n" (map (component: component.shellHook or "") components);

  dataRoot = "${paths.xdg.data.local}/${cfg.directory}";
  cacheRoot = "${paths.xdg.cache.local}/${cfg.directory}";
  privateRoot = paths.home.private.local;
in {
  inherit name env packages;

  shellHook = ''
    export AI_PRESET="${name}"
    export AI_INSTANCE="''${AI_INSTANCE:-${cfg.instance}}"
    export AI_BIND_ADDRESS="''${AI_BIND_ADDRESS:-${cfg.bindAddress}}"
    export AI_PORT_OFFSET="''${AI_PORT_OFFSET:-${toString cfg.portOffset}}"
    export AI_DATA_ROOT="${dataRoot}"
    export AI_CACHE_ROOT="${cacheRoot}"
    export AI_PRIVATE_DIR="${privateRoot}"
    export AI_HOME="''${AI_HOME:-$AI_DATA_ROOT/$AI_PRESET/$AI_INSTANCE}"
    export AI_CACHE_DIR="''${AI_CACHE_DIR:-$AI_CACHE_ROOT/$AI_PRESET/$AI_INSTANCE}"
    export HERMES_HOME="$AI_HOME/${cfg.hermes.state}"
    export HERMES_GATEWAY_CFG="$HERMES_HOME/${cfg.hermes.gateway}"

    mkdir -p "$AI_HOME" "$AI_CACHE_DIR" "$HERMES_HOME"

    ${init}
    ${hooks}

    if [ -t 1 ]; then
      ${start}
      printf '%s\n' "AI preset: $AI_PRESET ($AI_INSTANCE)"
      printf '%s\n' "State: $AI_HOME"
    fi
  '';
}
