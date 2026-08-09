{config, top, ...}: {
  programs.nix-index = {
    enable = config.${top}.inputs.applications.utilities.nix-index.enable;
    enableBashIntegration = config.programs.bash.enable;
    enableZshIntegration = config.programs.zsh.enable;
    enableFishIntegration = config.programs.fish.enable;
  };
  ${top}.output.programs.nix-index = config.programs.nix-index;
}
