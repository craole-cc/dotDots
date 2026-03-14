{pkgs, ...}: {
  programs.zed-editor = {
    package = pkgs.zed-editor-fhs;
    extensions = [
      "basher"
      "cargotoml"
      "catppuccin"
      "catppuccin-icons"
      "git-firefly"
      "marksman"
      "nix"
      "snippets"
      "toml"
      "typos"
      "zig"
      "jj-lsp"
    ];
  };
}
