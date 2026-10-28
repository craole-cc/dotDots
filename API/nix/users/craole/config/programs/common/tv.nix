{pkgs, ...}: {
  home.packages = with pkgs; [
    nix-search-tv
    # (writeShellApplication {
    #   name = "ns";
    #   runtimeInputs = [
    #     fzf
    #     nix-search-tv
    #   ];
    #   text = builtins.readFile "${nix-search-tv.src}/nixpkgs.sh";
    # })
  ];
}
