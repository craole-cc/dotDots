{
  pkgs,
  inputs,
  system,
  ...
}: {
  environment.systemPackages = with pkgs; [
    inputs.noctalia.packages.${system}.default
    cowsay
    # ... maybe other stuff
  ];
}
