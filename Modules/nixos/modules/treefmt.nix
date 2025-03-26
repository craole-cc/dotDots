# treefmt.nix
{ pkgs, ... }:
{
  projectRootFile = "flake.nix";

  programs = {
    nixfmt-rfc-style.enabled = true;
    shellcheck.enabled = true;
    shfmt.enabled = true;
  };

  settings.formatter = {
    shellcheck = {
      options = [
        "-s"
        "bash"
        "-f"
        "diff"
      ];
    };
  };
}
