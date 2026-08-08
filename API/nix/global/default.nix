{
  # Global names are persisted alongside the host/user API records.  `top` is
  # the namespace used by NixOS module inputs; callers may override it through
  # the root function's `topOverride` argument or DOTS_TOP environment variable.
  names = {
    top = "_";
  };
}
