{config, top, ...}: {
  programs.nix-index = {
    enable = config.${top}.applications.utilities.nix-index.enable;
    enableBashIntegration = config.programs.bash.enable;
    enableZshIntegration = config.programs.zsh.enable;
    enableFishIntegration = config.programs.fish.enable;
  };
}
