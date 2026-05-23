{dots, ...}: let
  description = "Minimal Dev Environment";
  inherit (dots) cache lix pkgs system inputPkgs;
  inherit (lix.lists.construction) optionals;

  #|---------------------------------------------------------|
  #| Packages -----------------------------------------------|
  #|---------------------------------------------------------|
  packages = (
    (with pkgs; [cowsay hello hello-wayland])
    ++ (with (inputPkgs "llm-agents"); [
      codex
      hermes-agent
    ])
    ++ (with (inputPkgs "vscode-insiders"); [
      ])
    ++ (with (inputPkgs "nix-vscode-extensions"); [
      ])
    ++ (with (inputPkgs "typix"); [
      ])
  );
  #|---------------------------------------------------------|
  #| Shell Configuration  -----------------------------------|
  #|---------------------------------------------------------|
  env = {};
  shellHook = ''Be Productive, Be Commited, Be Resolute'';
in {inherit description env packages shellHook;}
