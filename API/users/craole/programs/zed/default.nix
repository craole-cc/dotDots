{
  pkgs,
  policies,
  ...
}:
{
  programs.zed-editor.enable = policies.devGui;
  imports = [
    # ./settings.nix
    ./extensions.nix
  ];
}
