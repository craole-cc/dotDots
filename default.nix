{
  stores ? {
    src = ./.;
    lib = ./Libraries/nix;
    api = ./API/nix;
  },
  ...
} @ args:
import stores.lib args
