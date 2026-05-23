{dots, ...}: let
  description = "Minimal Dev Environment";
  inherit (dots) cache lix pkgs system inputPkgs;
  inherit (lix.lists.construction) optionals;

  #|---------------------------------------------------------|
  #| Packages -----------------------------------------------|
  #|---------------------------------------------------------|
  packages = (
    # with (inputPkgs "llm-agents"); [
    with pkgs.llm-agents; [
      codex
      # hermes-agent
    ]
  );
  #|---------------------------------------------------------|
  #| Shell Configuration  -----------------------------------|
  #|---------------------------------------------------------|
  env = {};
  shellHook = '''';
in {inherit description env packages shellHook;}
