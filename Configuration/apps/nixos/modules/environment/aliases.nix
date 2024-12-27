{ specialArgs, ... }:
let
  inherit (specialArgs.paths) flake;
in
{
  environment.shellAliases = {
    Flake = ''if command -v geet ; then geet ; else git add --all; git commit --message "Flake Update" ; fi ; sudo nixos-rebuild switch --flake . --show-trace'';
    Flash-local = ''geet --path ${flake.local} && sudo nixos-rebuild switch --flake ${flake.local} --show-trace'';
    Flash-root = ''geet --path ${flake.root} && sudo nixos-rebuild switch --flake ${flake.root} --show-trace'';
    # Flash-link = ''geet --path ${flake.link} && sudo nixos-rebuild switch --flake ${flake.link} --show-trace'';
    Flash = ''Flash-local'';
    Flick = ''Flush && Flash && Reboot'';
    Flick-local = ''Flush && Flash-local && Reboot'';
    Flick-root = ''Flush && Flash-root && Reboot'';
    # Flick-link = ''Flush && Flash-link && Reboot'';
    Flush = ''sudo nix-collect-garbage --delete-old; sudo nix-store --gc'';
    Reboot = ''leave --reboot'';
    Reload = ''leave --logout'';
    Retire = ''leave --shutdown'';
    Q = ''kill -KILL "$(ps -o ppid= -p $$)"'';
    q = ''leave --terminal'';
    h = "history";
    ".dots-local" = ''cd ${flake.local}'';
    ".dots-root" = ''cd ${flake.root}'';
    ".dots-link" = ''cd ${flake.link}'';
    ".." = "cd ..";
    "..." = "cd ../..";
    "...." = "cd ../../..";
    "....." = "cd ../../../..";
  };
}
