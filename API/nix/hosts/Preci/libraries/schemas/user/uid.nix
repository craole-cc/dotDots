{lix, ...}: let
  inherit (lix.debug) requireThat;
  inherit (lix.strings) hashString;
  inherit (lix.strings) substring;
  inherit (lix.trivial) div fromHexString;

  default = null;

  ranges = let
    system = {
      min = 400;
      max = 999;
    };
    normal = {
      min = 1000;
      max = 59999;
    };
  in {
    administrator = normal;
    user = normal;
    guest = normal;
    service = system;
  };

  # Deterministic pseudo-random uid seeded by role + name: the same
  # pair always resolves to the same uid, spread across that role's
  # allotted range. Expects `role` to already be normalized (i.e.
  # already resolved through role.nix) — a raw alias like "daemon"
  # will just miss `ranges` and fall through to the `user` pool.
  seedUid = {
    role,
    name,
    range,
  }: let
    hash = hashString "sha256" "${role}:${name}";
    seed = fromHexString (substring 0 8 hash);
    span = range.max - range.min + 1;
    m = seed - span * (div seed span);
  in
    range.min + m;

  resolve = {
    uid ? args.uid or default,
    name ? args.name or null,
    role ? args.role or "user",
    context ? "resolve user uid (user \"${toString name}\")",
    ...
  } @ args: let
    range =
      ranges.${role} or ranges.user;
    resolved =
      if uid != null
      then uid
      else seedUid {inherit role name range;};
  in
    assert requireThat {
      inherit context;
      condition = builtins.isInt resolved && resolved >= 0;
      message = "uid must be a non-negative integer, got '${toString resolved}'";
    }; resolved;
in {inherit default resolve;}
