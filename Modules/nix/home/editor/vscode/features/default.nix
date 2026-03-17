{
  pkgs,
  inputs,
  lib,
  lix,
}: let
  inherit (lix.types.options) mkTrue mkFalse;

  load = path: import path {inherit pkgs inputs lib lix;};
in {
  ai = load ./ai.nix;
  appearance = load ./appearance.nix;
  decorations = load ./decorations.nix;
  infrastructure = load ./infrastructure.nix;
  markup = load ./markup.nix;
  nix = load ./nix.nix;
  productivity = load ./productivity.nix;
  scripting = load ./scripting.nix;
  systems = load ./systems.nix;
  vcs = load ./vcs.nix;
  web = load ./web.nix;

  options = {
    ai = mkTrue "AI assistance extensions";
    appearance = mkTrue "Themes, icons and UI chrome extensions";
    decorations = mkTrue "Inline highlights, guides and visual aids";
    infrastructure = mkFalse "Docker, SQL, DevOps extensions";
    markup = mkTrue "Markdown, TOML, YAML, config format extensions";
    nix = mkTrue "Nix language and tooling extensions";
    productivity = mkTrue "Workflow, file management and utility extensions";
    scripting = mkTrue "Python, Nushell, PowerShell extensions";
    systems = mkTrue "Rust, shell and systems programming extensions";
    vcs = mkTrue "Git, jj and version control extensions";
    web = mkTrue "Web development extensions";
  };
}
