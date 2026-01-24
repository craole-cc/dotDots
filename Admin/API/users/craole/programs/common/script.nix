{pkgs, ...}: {
  home.packages = with pkgs; [
    gcc
    rust-script
    powershell
    shellcheck
    shfmt
    nixfmt
    alejandra
    nil
    nixd
    powershell
    powershell-editor-services
  ];
}
