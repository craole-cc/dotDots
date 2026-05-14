{ pkgs, ... }:
pkgs.symlinkJoin {
  name = "gh-tools-${pkgs.gh.version}";

  paths = [ pkgs.gh ];

  nativeBuildInputs = [ pkgs.makeWrapper ];

  #? gh already reads GITHUB_TOKEN from the environment; this wrapper
  #? documents and enforces that contract and adds a helpful error message.
  postBuild = ''
    wrapProgram "$out/bin/gh" \
      --run 'if [ -z "''${GITHUB_TOKEN:-}" ]; then
              echo "gh-tools: GITHUB_TOKEN is not set." >&2
              echo "Set it in .envrc.local — never commit it." >&2
              exit 1
            fi'
  '';

  meta = pkgs.gh.meta // {
    description = "GitHub CLI wrapped to require GITHUB_TOKEN from environment";
  };
}
