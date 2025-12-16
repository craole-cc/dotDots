{
  config,
  policies,
  ...
}:
let
  # isAllowed = policies.dev;
  isAllowed = true;
  isEnabled = pkg: config.programs.${pkg}.enable;
in
{
  programs.atuin = {
    enable = isAllowed;
    daemon.enable = isAllowed;
    enableBashIntegration = isEnabled "bash";
    enableNushellIntegration = isEnabled "nushell";
    enableFishIntegration = isEnabled "fish";
    enableZshIntegration = isEnabled "zsh";
  };
  imports = [
    ./settings.nix
    # ./themes.nix
  ];
}
