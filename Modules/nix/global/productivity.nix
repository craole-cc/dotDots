{dots, ...}: let
  description = "Minimal Dev Environment";
  inherit (dots) pkgs system inputs inputPkgs;

  #|---------------------------------------------------------|
  #| Packages -----------------------------------------------|
  #|---------------------------------------------------------|
  packages = (
    (with pkgs; [cowsay hello hello-wayland])
    ++ (with (inputPkgs "llm-agents"); [
      # codex
      hermes-agent
    ])
    # ++ (with (inputPkgs "vscode-insiders"); [default])
    # ++ (
    #   with inputs.nix-vscode-extensions.extensions.${system}; (
    #     with vscode-marketplace; [
    #       eldritch.eldritch
    #       jnoortheen.nix-ide
    #     ]
    #   )
    # )
    # ++ (with (inputPkgs "typix"); [
    #   ])
  );
  #|---------------------------------------------------------|
  #| Shell Configuration  -----------------------------------|
  #|---------------------------------------------------------|
  env = {};
  shellHook = ''
    nitch
    gum style --italic --bold \
      "Be Productive, Be Commited, Be Resolute"
  '';
in {inherit description env packages shellHook;}
