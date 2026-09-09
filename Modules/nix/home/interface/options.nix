{
  user,
  lix,
  top,
  ...
}: {
  # mkUsers enriches each user with an already-normalized interface. Expose
  # that schema result to Home exactly once so mkContext consumers share the
  # same resolved contract as Core without re-normalizing host/user data.
  options.${top}.resolved.interface = lix.schema.ui.mkOptions {
    ui = user.interface;
  };
}
