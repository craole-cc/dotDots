args: let
  router = import ./router args;
  memory = import ./memory args;
  hermes = import ./agents/hermes (args // {HOME = args.HOME or "/home/craole";});
in {
  description = "AI Development";

  agents = {inherit hermes;};
  inherit memory router;
  env =
    (args.env or {})
    // router.env
    // memory.env
    // hermes.env;

  packages =
    router.packages
    ++ memory.packages
    ++ hermes.packages;

  shellHook = ''
    if [ -t 1 ]; then
      printf "%s\n" "AI shell: OmniRoute + Mem0 + Hermes"
      printf "%s\n" "Focused shells: nix develop .#router | .#memory | .#hermes"
    fi
  '';
}
