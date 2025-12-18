# {pkgs ? import <nixpkgs> {}}: {
#   default = pkgs.mkShell {
#     NIX_CONFIG = "extra-experimental-features = nix-command flakes";
#     shellHook = "nix develop";
#   };
# }
{pkgs ? import <nixpkgs> {}}: {
  default = pkgs.mkShell {
    shellHook = ''
      # Set NIX_CONFIG only when needed
      export NIX_CONFIG="extra-experimental-features = nix-command flakes"

      # Debug: Check environment size
      echo "Environment size: $(env | wc -c) bytes"
    '';
  };
}
