{
  user,
  lib,
  top,
  ...
}: let
  utilityNames = [
    "atuin"
    "bat"
    "btop"
    "clock"
    "delta"
    "direnv"
    "git"
    "github"
    "gitui"
    "grep"
    "home-manager"
    "jujutsu"
    "nh"
    "nix-index"
    "topgrade"
    "tmux"
    "yazi"
  ];
  apiUtilities = user.applications.utilities or {};
in {
  options.${top}.resolved.applications.utilities =
    lib.genAttrs utilityNames (name: {
      enable = lib.mkOption {
        description = "Enable the ${name} user utility";
        default = lib.attrByPath [name "enable"] false apiUtilities;
        type = lib.types.bool;
      };
    });
}
