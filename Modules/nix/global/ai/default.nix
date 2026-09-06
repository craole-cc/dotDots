{
  args,
  core,
  ...
}: let
  inherit (args) pkgs;
  inherit (pkgs) mkShell;

  router = import ./router args;
  hindsight = import ./memory/hindsight (args // {env = args.env or {};});
  hermes = import ./agents/hermes (args // {env = args.env or {};});

  aiShell = {
    description = "AI Development";
    agents = {inherit hermes;};
    memory = {inherit hindsight;};
    env = (args.env or {}) // hindsight.env // hermes.env;
    packages = hindsight.packages ++ hermes.packages;
    shellHook = ''
      ${hindsight.shellHook}
      ${hermes.shellHook}

      if [ -t 1 ]; then
        printf "%s\n" "AI shell: Hermes + Hindsight"
        printf "%s\n" "Focused shells: nix develop .#ai-hermes | .#ai-hindsight"
        printf "%s\n" "Optional router: nix develop .#ai-router"
      fi
    '';
  };

  aiRouter = {
    env = core.env // router.env;
    inherit (router) shellHook;
    packages = core.packages ++ router.packages;
  };

  aiHermes = {
    env = core.env // hermes.env;
    inherit (hermes) shellHook;
    packages = core.packages ++ hermes.packages;
  };

  aiHindsight = {
    env = core.env // hindsight.env;
    inherit (hindsight) shellHook;
    packages = core.packages ++ hindsight.packages;
  };

  devShells = {
    ai = mkShell {
      name = "dots-ai";
      inherit (aiShell) env shellHook packages;
    };

    "ai-hermes" = mkShell {
      name = "dots-ai-hermes";
      inherit (aiHermes) env shellHook packages;
    };

    "ai-hindsight" = mkShell {
      name = "dots-ai-hindsight";
      inherit (aiHindsight) env shellHook packages;
    };

    "ai-router" = mkShell {
      name = "dots-ai-router";
      inherit (aiRouter) env shellHook packages;
    };
  };
in {
  inherit devShells;
  inherit (aiShell) description env packages shellHook;
}
