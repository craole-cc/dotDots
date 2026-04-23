{
  pkgs,
  inputs,
  ...
}: {
  checks = {
    openclaw-unit = import ./openclaw.nix {inherit pkgs inputs;};
    format = import ./format.nix {inherit pkgs inputs;};
    secrets-lint = import ./secrets.nix {inherit pkgs;};
  };
}
