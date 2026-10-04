{lix, ...}: let
  __ = {inherit lix;};
  inherit (lix.attrsets) recursiveUpdate;
  inherit (lix.schemas) declareFields resolveFields;
  inherit (lix.lists) concatMap elemAt foldl' head length optionals reverseList tail unique;

  fields = {
    applications = import ./applications.nix __;
    autoLogin = import ./autoLogin.nix __;
    capabilities = import ./capabilities.nix __;
    description = import ./description.nix __;
    enable = import ./enable.nix __;
    git = import ./git.nix __;
    interface = import ./interface.nix __;
    localisation = import ./localisation.nix __;
    name = import ./name.nix __;
    packages = import ./packages.nix __;
    hashedPassword = import ./hashedPassword.nix __;
    paths = import ./paths.nix __;
    role = import ./role.nix __;
    uid = import ./uid.nix __;
  };
  default = declareFields fields;
  resolve = domain: resolveFields domain fields;

  mkUser = {
    users,
    user,
  }:
    resolve (recursiveUpdate (users.${user.name} or {}) user);

  mkUsers = users: let
    defined = map (user: mkUser {inherit users user;}) users;

    count = length defined;

    primary =
      if count > 0
      then head defined
      else null;

    secondary =
      if count > 1
      then elemAt defined 1
      else null;

    tertiary =
      if count > 2
      then elemAt defined 2
      else null;

    others = optionals (count > 3) (tail (tail (tail defined)));

    names = map (user: user.name) defined;

    interface = {
      desktops = unique (
        concatMap
        (user: user.interface.desktops or [])
        defined
      );
      fonts = {
        clock = unique (
          concatMap
          (user: user.interface.fonts.clock or [])
          defined
        );
        emoji = unique (
          concatMap
          (user: user.interface.fonts.emoji or [])
          defined
        );
        material = unique (
          concatMap
          (user: user.interface.fonts.material or [])
          defined
        );
        monospace = unique (
          concatMap
          (user: user.interface.fonts.monospace or [])
          defined
        );
        sans = unique (
          concatMap
          (user: user.interface.fonts.sans or [])
          defined
        );
        serif = unique (
          concatMap
          (user: user.interface.fonts.serif or [])
          defined
        );
      };
      themes = foldl' recursiveUpdate {} (
        reverseList (
          map
          (user: user.interface.themes or {})
          defined
        )
      );
      cursors = foldl' recursiveUpdate {} (
        reverseList (
          map
          (user: user.interface.cursors or {})
          defined
        )
      );
      keyboard = foldl' recursiveUpdate {} (
        reverseList (
          map
          (user: user.interface.keyboard or {})
          defined
        )
      );
    };
  in {inherit defined count interface names others primary secondary tertiary;};
in
  fields // {inherit default mkUsers mkUser;}
