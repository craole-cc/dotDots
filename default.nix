{
  stores ? {
    src = ./.;
    lib = ./Libraries/nix;
    api = ./API/nix;
  },
  ...
} @ args: let
  defaults = {
    # TODO:  Is it still being used? Why is this still being used? I'm pretty sure I updated Libraries/sources/inputs.nix so this could be removed.
    inputs = {
      config = {
        allowUnfree = true;
        allowBroken = false;
      };
      core = {
        attrs = "legacyPackages";
        names = ["nixpkgs" "nixpkgs-stable" "nixpkgs-unstable"];
      };
      home = {
        attrs = "packages";
        names = [
          "age"
          "niri-float-sticky"
          "caelestia"
          "catppuccin"
          "codex"
          "buuf-icons"
          "codex-plugins"
          "codex-skills"
          "dank-material-shell"
          "dms-plugin-registry"
          "fresh-editor"
          "helix"
          "hermes-agent"
          "home-manager"
          "llm-agents"
          "noctalia-shell"
          "nvf"
          "plasma"
          "quickshell"
          "treefmt"
          "typix"
          "vscode-insiders"
          "warp-terminal"
          "zen-browser"
        ];
      };
    };
  };
in
  import stores.lib (args // {defaults = (args.defaults or {}) // defaults;})
