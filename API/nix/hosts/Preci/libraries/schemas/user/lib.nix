{
  lib,
  lix,
  resolve,
  ...
}: let
  inherit (lib.attrsets) recursiveUpdate;
  inherit (lib.lists) concatMap elemAt foldl' head length optionals reverseList tail unique;

  mkUser = {
    args,
    principal,
  }: let
    source = recursiveUpdate (args.users.${principal.name} or {}) principal;
  in
    resolve source;

  mkUsers = {
    args,
    principals,
  }: let
    all = map (principal: mkUser {inherit args principal;}) principals;
    count = length all;
    primary = head all;
    secondary = if count > 1 then elemAt all 1 else null;
    tertiary = if count > 2 then elemAt all 2 else null;
    others = optionals (count > 3) (tail (tail (tail all)));
    names = map (principal: principal.name) all;
    interface = {
      desktops = unique (concatMap (principal: principal.interface.desktops or []) all);
      fonts = {
        clock = unique (concatMap (principal: principal.interface.fonts.clock or []) all);
        emoji = unique (concatMap (principal: principal.interface.fonts.emoji or []) all);
        material = unique (concatMap (principal: principal.interface.fonts.material or []) all);
        monospace = unique (concatMap (principal: principal.interface.fonts.monospace or []) all);
        sans = unique (concatMap (principal: principal.interface.fonts.sans or []) all);
        serif = unique (concatMap (principal: principal.interface.fonts.serif or []) all);
      };
      themes = foldl' recursiveUpdate {} (reverseList (map (principal: principal.interface.themes or {}) all));
      cursors = foldl' recursiveUpdate {} (reverseList (map (principal: principal.interface.cursors or {}) all));
      keyboard = foldl' recursiveUpdate {} (reverseList (map (principal: principal.interface.keyboard or {}) all));
    };
  in {
    inherit all count interface names others primary secondary tertiary;
  };
in {inherit mkUser mkUsers;}
