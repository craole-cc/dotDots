{
  policies,
  lib,
  ...
}:
{
  programs.yazi = lib.mkIf policies.dev {
    enable = true;
  };
}
