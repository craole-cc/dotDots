{
  lix,
  cfg,
  tools,
  ...
}: let
  inherit (lix.options.construction) mkOption;
  inherit (lix.types.primitives) package;
in {
  options.cli.package = mkOption {
    type = package;
    default = tools.records.codex.package;
    description = ''
      Codex CLI, taken from the flake inputs rather than nixpkgs, so it
      tracks upstream releases more closely (`programs.codex.package`).
    '';
  };

  program.package = cfg.cli.package;
}
