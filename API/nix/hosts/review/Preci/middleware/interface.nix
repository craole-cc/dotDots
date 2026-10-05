{
  lix,
  host ? {},
  ...
}: let
  inherit (lix.attrsets) attrNames isAttrs;
  inherit (lix.lists) concatMap head optionals unique;
  inherit (lix.strings) concatStringsSep;

  #? `mkMergedList` puts `requested` first and appends `defaults`, so the
  #? requester's order is preserved and the host's declarations fill in
  #? behind. That is the priority rule: the primary principal's preferences
  #? lead, later principals follow, and the host is the fallback, not an
  #? override.
  inherit (lix.lists) mkMergedList;

  #? The same normalisation `functionalities.nix` performs: a field may be
  #? declared as a list of names or as an attrset of names to detail, and
  #? either shape yields the same list view.
  names = value:
    if value == null
    then []
    else if isAttrs value
    then unique (attrNames value)
    else unique value;

  #? The principals in *declared* order, so index 0 is the primary user;
  #? `mkUsers` derives `primary`/`secondary` from that same list. Read inline
  #? rather than through a local binding: there is no second name for it, and
  #? `defined` already says what the list is.
  #?
  #? What each principal asked for, concatenated in principal order. Reading
  #? `.interface.desktops` per user rather than from a pre-merged host value
  #? keeps the request side here, where the two sides can actually meet.
  requestedOf = user: names (user.interface.desktops or []);
  requested = unique (concatMap requestedOf (
    host.principals.defined or []
  ));

  #? What the host declares. Read exactly like `functionalities` -- a
  #? presence list of names.
  #?
  #? This is NOT a ceiling. The host declares what it manages, the principals
  #? declare what they want, and a host with only `plasma` still offers
  #? `hyprland` and `niri` to a principal who asked for them. Restricting
  #? `available` to the intersection would cap a user to whatever the host
  #? happened to name, which is the opposite of what `available` means.
  provided = names (host.interface.desktops or []);

  #? `default` is singular because the argument name matches the local binding
  #? it feeds. Passing `defaults` here matches neither, and because the helper
  #? falls back to `[]` an unrecognised spelling does not throw -- it silently
  #? discards the host's declarations and leaves only the principals' requests.
  merge = mkMergedList {inherit requested provided;};
  inherit (merge) ordered;

  #? A request is ignored when the host's *posture* cannot present it, not
  #? when the host's declaration omits it. On a graphical host this is empty
  #? even if the host names only one desktop; on a tty-only host it is every
  #? graphical desktop requested, because none of them can be presented.
  ignored = optionals (!graphical) ordered;

  #? Host posture: whether this machine can present a graphical session at
  #? all. Unlike `provided`, this genuinely removes options -- a tty-only
  #? host cannot run a compositor no matter which principal asks.
  #?
  #? Matched as a named ladder rather than a chain of string comparisons, so
  #? an unrecognised posture fails with the vocabulary in the message instead
  #? of quietly comparing unequal to everything and taking the last branch.
  #?
  #? Nix has no usable `case` for this: `case` cannot appear as an expression
  #? inside `let` in 2.34, and `mkCase` is not part of this scoped `lix`.
  #?
  #? Defaulted to `graphical` so a host that declares nothing keeps today's
  #? behaviour: nothing is ignored on the strength of an absent field.
  posture = host.interface.posture or "graphical";

  graphical =
    if posture == "graphical"
    then true
    else if posture == "tty"
    then false
    else if posture == "none"
    then false
    else
      throw "context interface: unknown host posture '${
        toString posture
      }' (expected 'graphical', 'tty' or 'none')";
in {
  desktops = {
    inherit requested provided ordered ignored posture;

    #? The default session is the head of the merged list. `mkMergedList` put
    #? the principal's requests ahead of the host's declarations, so the head is
    #? already the primary principal's first preference -- no second filter
    #? against `provided` is needed, and adding one would quietly cap the user to
    #? whatever the host happened to name.
    default =
      if graphical && ordered != []
      then head ordered
      else null;
  };

  #? The merged record, exposed so the rule stays auditable: a module can read
  #? `.defaults`/`.overrides` to see the two sides without reconstructing the
  #? merge. `.desktops` above is the plain view.
  merge = {
    inherit (merge) defaults overrides ordered;
  };

  #? Findings are data, not `builtins.trace`. Trace output goes to stderr
  #? during evaluation and is invisible in a `nixos-rebuild` log, so a
  #? reconciled-away request would be silently ignored again -- which is the
  #? failure this file exists to close. A module feeds these into NixOS's
  #? `warnings` option, which does reach the build log.
  warnings = optionals (ignored != []) [
    "context interface: host '${
      toString (host.name or "?")
    }' has posture '${posture}'; desktop(s) ${
      concatStringsSep ", " ignored
    } were requested but cannot be presented"
  ];
}
