{pkgs, ...}: {
  programs.bash.shellAliases = {
    la = "lsd --almost-all";
    ll = "la --long";
    nos_gc = "sudo nix-collect-garbage --delete-old";
    nos_rbs = "sudo nixos-rebuild switch";
    # ls = "lsd";
    # wsl = "";
  };
}
