args: let
  mem0 = import ./mem0 args;
  hindsight = import ./hindsight args;
in {
  inherit (mem0) mem0 status verify;
  inherit hindsight;

  packages = mem0.packages ++ hindsight.packages;
  env = mem0.env // hindsight.env;
  shellHook = ''
    ${mem0.shellHook}
    ${hindsight.shellHook}
  '';
}
