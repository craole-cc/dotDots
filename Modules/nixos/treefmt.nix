# treefmt.nix
{ pkgs, ... }:
{
  projectRootFile = "flake.nix";

  programs = {
    nixfmt = {
      enabled = true;
      package = pkgs.nixfmt-rfc-style;
    };

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
