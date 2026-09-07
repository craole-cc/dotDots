{
  args,
  core,
  ...
}: let
  inherit (args) pkgs;
  inherit (pkgs) mkShell;

  agents = import ./agents args;
  memory = import ./memory args;
  router = import ./router args;
  presets = import ./presets (args // {inherit agents memory router;});

  mkPresetShell = preset:
    mkShell {
      name = "dots-${preset.name}";
      env = core.env // preset.env;
      packages = core.packages ++ preset.packages;
      inherit (preset) shellHook;
    };

  mkComponentShell = name: component:
    mkShell {
      name = "dots-ai-${name}";
      env = core.env // (component.env or {});
      packages = core.packages ++ (component.packages or []);
      shellHook = component.shellHook or "";
    };

  shells = builtins.mapAttrs (_: mkPresetShell) presets;
  default = presets."ai-hermes-hindsight";

  devShells =
    shells
    // {
      ai = shells."ai-hermes-hindsight";
      "ai-hindsight" = mkComponentShell "hindsight" memory.hindsight;
      "ai-mem0" = mkComponentShell "mem0" memory.mem0;
      "ai-omniroute" = mkComponentShell "omniroute" router.omniroute;
    };
in {
  inherit devShells;
  inherit (default) env packages shellHook;
  description = "AI Development";
}
