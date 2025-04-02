{
  pkgs,
  paths ? null,
  ...
}:
{
  aider-chat-env = pkgs.callPackage ./aider { };
  lyrics = pkgs.python3Packages.callPackage ./lyrics { };
  devshell = if paths != null then pkgs.callPackage ./devshell { inherit paths; } else null;
}
