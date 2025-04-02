{
  pkgs ? import <nixpkgs> { },
  ...
}:
{
  aider-chat-env = pkgs.callPackage ./aider { };
  lyrics = pkgs.python3Packages.callPackage ./lyrics { };
  devshell = pkgs.callPackage ./devshell { };
}
