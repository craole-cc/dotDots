{
  name,
  components,
  init ? "",
  start ? "",
}: let
  env = builtins.foldl' (acc: component: acc // (component.env or {})) {} components;
  packages = builtins.concatLists (map (component: component.packages or []) components);
  hooks = builtins.concatStringsSep "\n" (map (component: component.shellHook or "") components);
in {
  inherit name env packages;

  shellHook = ''
    export AI_PRESET="${name}"
    export AI_INSTANCE="''${AI_INSTANCE:-default}"
    export AI_HOME="''${AI_HOME:-''${XDG_DATA_HOME:-$HOME/.local/share}/ai/$AI_PRESET/$AI_INSTANCE}"
    export HERMES_HOME="$AI_HOME/hermes"
    export HERMES_GATEWAY_CFG="$HERMES_HOME/gateway.json"

    mkdir -p "$AI_HOME" "$HERMES_HOME"

    ${init}
    ${hooks}

    if [ -t 1 ]; then
      ${start}
      printf '%s\n' "AI preset: $AI_PRESET ($AI_INSTANCE)"
      printf '%s\n' "State: $AI_HOME"
    fi
  '';
}
