{dots, ...}: let
  description = "Minimal Dev Environment";
  inherit (dots) pkgs inputPkgs;

  #|---------------------------------------------------------|
  #| Packages -----------------------------------------------|
  #|---------------------------------------------------------|
  llms = inputPkgs "llm-agents";

  packages = (
    (with pkgs; [nodejs_22])
    ++ (with llms; [hermes-agent])
  );

  #|---------------------------------------------------------|
  #| Shell Configuration  -----------------------------------|
  #|---------------------------------------------------------|
  env = {};
  shellHook = ''
    nitch
    gum style --italic --bold \
      "Be Productive, Be Committed, Be Resolute"
  '';
in {inherit description env packages shellHook;}
