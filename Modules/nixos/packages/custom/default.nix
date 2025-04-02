{
  pkgs,
  # paths ? null,
  ...
}:
{
  aider-chat-env = pkgs.callPackage ./aider { };
  lyrics = pkgs.python3Packages.callPackage ./lyrics { };
  # devshell = pkgs.callPackage ./devshell {
  #   inherit paths;
  #   inherit (pkgs.inputs.developmentShell) mkShell;
  # };

  devshell =
    if paths == null then
      null
    else
      pkgs.callPackage ./devshell {
        # inherit paths;
        # inherit (pkgs.inputs.developmentShell) mkShell;
      };

}
