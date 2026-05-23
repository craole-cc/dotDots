{dots, ...}: let
  description = "Minimal Dev Environment";
  inherit (dots) pkgs system inputs inputPkgs;

  #|---------------------------------------------------------|
  #| Packages -----------------------------------------------|
  #|---------------------------------------------------------|
  llm = inputPkgs "llm-agents";

  packages = (
    (with pkgs; [nodejs_22])
    ++ (with llm; [
      # codex
      (hermes-agent.overrideAttrs ({postInstall ? "", ...}: {
        postInstall =
          postInstall
          + ''
            mkdir -p "$out"/lib/python3.13/site-packages/scripts
            cp -r "$src"/scripts/whatsapp-bridge "$out"/lib/python3.13/site-packages/scripts/
          '';
      }))
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
