{
  host,
  policies,
  ...
}: let
  enable = policies.devGui && host.interface.displayProtocol == "wayland";
in {
  programs.foot = {
    inherit enable;
    server = {inherit enable;};
  };
  imports = [
    ./settings.nix
    ./themes.nix
  ];
}
