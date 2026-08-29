{
  src ? ../../..,
}:
{
  mkLib = {
    lib ? null,
    flake ? {},
    target ? null,
  }:
    import (src + "/Libraries/nix") {
      inherit lib flake target;
      host = target;
      inherit src;
    };
}
