{
  inputs,
  lix,
  paths,
  pkgs,
  ...
}: let
  inherit (lix.filesystem.traversal) importWithArgs;
  inherit (lix.lists.construction) optionals;
  inherit (lix.lists.predicates) all;
  inherit (lix.attrsets.transformation) mapAttrs;
  inherit (lix.filesystem.access) readFile;
  inherit (pkgs) mkShell stdenv;
  inherit (stdenv) isLinux isDarwin;

  cfg = {
    name = "dotDots";
    version = "2.0.0";
    cache = ".cache";
    prefix = ".";
    allowAI = true;
  };

  shared = import ./shared {inherit inputs lix paths pkgs;};
  inherit (shared) formatter checks;

  #~@ Shell Logic Consolidation
  devShells = let
    #> Build the final derivations
    shells =
      mapAttrs (
        name: cfg:
          mkShell {
            name = "${cfg.name}-${name}";
            env = cfg.env or {};
            shellHook = cfg.shellHook or "";
            packages = cfg.packages ++ (cfg.packages or []);
          }
      )
      #> Import every subdirectory under ./shells (minimal, ai, python, ...),
      #> each keyed by its folder name, using its default.nix
      (importWithArgs {
        path = ./shells;
        args = cfg // shared;
        excludes = [];
      });

    resolved = shells // {default = shells.core;};
    versions = let
      toolchain = fromTOML (readFile (paths.src + "/toolchain.toml"));

      verify = section: name: let
        expected = toolchain.${section}.${name};
        actual = pkgs.${name}.version;
      in
        (actual == expected)
        || throw ''
          Version mismatch for '${name}':
            Expected: ${expected}
            Actual:   ${actual}
        '';

      tools = {
        general = [
          "bat"
          "direnv"
          "eza"
          "fd"
          "jq"
          "lsd"
          "pandoc"
          "ripgrep"
          "sd"
          "starship"
          "typst"
          "yazi"
          "zoxide"
        ];
        nix = [
          "cargo"
          "gcc"
          "mise"
          "nushell"
          "rustc"
          "tldr"
        ];
      };
    in
      (map (verify "general") tools.general)
      ++ (map (verify "nix") tools.nix);
  in
    assert all (valid: valid) versions;
      shells // {default = shells.minimal;};
in {inherit checks devShells formatter;}
