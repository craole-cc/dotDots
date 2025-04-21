{pkgs, ...}: {
  aider-chat-env = pkgs.callPackage ./env.nix {};
}
