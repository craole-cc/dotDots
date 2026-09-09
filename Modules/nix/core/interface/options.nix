{
  host,
  lix,
  top,
  ...
}: {
  # The host schema is already normalized before it reaches Core. Materialize
  # that resolved interface as NixOS options so mkContext consumers read the
  # same selection without re-normalizing host data or depending on Home.
  options.${top}.resolved.interface = lix.schema.ui.mkOptions {
    ui = host.interface;
  };
}
