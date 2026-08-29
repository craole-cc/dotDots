{
  args,
  core,
  ...
}: let
  inherit (args) pkgs;
  inherit (pkgs) mkShell;

  router = import ./router args;
  memory = import ./memory args;
  hermes = import ./agents/hermes (args // {
    HOME = args.paths.home.local;
    env = args.env or {};
  });

  aiShell = {
    description = "AI Development";
    agents = {inherit hermes;};
    inherit memory router;
    env = (args.env or {}) // router.env // memory.env // hermes.env;
    packages = router.packages ++ memory.packages ++ hermes.packages;
    shellHook = ''
      if [ -t 1 ]; then
        printf "%s\n" "AI shell: OmniRoute + Mem0 + Hermes"
        printf "%s\n" "Focused shells: nix develop .#ai-router | .#ai-memory | .#ai-hermes | .#ai-hindsight"
      fi
    '';
  };

  aiRouter = {
    env = core.env // router.env;
    inherit (router) shellHook;
    packages = core.packages ++ router.packages;
  };

  aiMemory = {
    env = core.env // memory.env;
    inherit (memory) shellHook;
    packages = core.packages ++ memory.packages;
  };

  aiHermes = {
    env = core.env // hermes.env;
    inherit (hermes) shellHook;
    packages = core.packages ++ hermes.packages;
  };

  aiHindsight = {
    env = core.env // memory.hindsight.env;
    inherit (memory.hindsight) shellHook;
    packages = core.packages ++ memory.hindsight.packages;
  };

  devShells = {
    ai = mkShell {
      name = "dots-ai";
      inherit (aiShell) env shellHook packages;
    };

    "ai-router" = mkShell {
      name = "dots-ai-router";
      inherit (aiRouter) env shellHook packages;
    };

    "ai-memory" = mkShell {
      name = "dots-ai-memory";
      inherit (aiMemory) env shellHook packages;
    };

    "ai-hermes" = mkShell {
      name = "dots-ai-hermes";
      inherit (aiHermes) env shellHook packages;
    };

    "ai-hindsight" = mkShell {
      name = "dots-ai-hindsight";
      inherit (aiHindsight) env shellHook packages;
    };
  };
in {
  inherit devShells;
  inherit (aiShell) description;
  inherit (aiShell) env;
  inherit (aiShell) packages;
  inherit (aiShell) shellHook;
}
