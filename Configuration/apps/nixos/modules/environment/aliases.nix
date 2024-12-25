{ specialArgs, ... }:
let
  # flake = specialArgs.paths.flake.local;
  inherit (specialArgs.paths) flake;
in
{
  environment.shellAliases = {
    Flake = ''pushd ${flake.local} && { { { command -v geet && geet ;} || git add --all; git commit --message "Flake Update" ;} ; sudo nixos-rebuild switch --flake . --show-trace ;}; popd'';
    Flush = ''sudo nix-collect-garbage --delete-old; sudo nix-store --gc'';
    Flash = ''geet --path ${flake.local} && sudo nixos-rebuild switch --flake ${flake.local} --show-trace'';
    Flash-root = ''geet --path ${flake.root} && sudo nixos-rebuild switch --flake ${flake.root} --show-trace'';
    Flash-link = ''geet --path ${flake.link} && sudo nixos-rebuild switch --flake ${flake.link} --show-trace'';
    "..local" = ''cd ${flake.local} || exit'';
    "..root" = ''cd ${flake.root} || exit'';
    "..link" = ''cd ${flake.link} || exit'';
    Flick = ''Flush && Flash && Reboot'';
    Reboot = ''leave --reboot'';
    Reload = ''leave --logout'';
    Retire = ''leave --shutdown'';
    Q = ''kill -KILL "$(ps -o ppid= -p $$)"'';
    q = ''leave --terminal'';
    ".." = "cd .. || return 1";
    "..." = "cd ../.. || return 1";
    "...." = "cd ../../.. || return 1";
    "....." = "cd ../../../.. || return 1";
    h = "history";
  };
}
