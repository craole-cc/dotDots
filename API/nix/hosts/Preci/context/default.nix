{
  lix,
  #? The raw host declaration, as produced by `specs/`.
  specs ? null,
  #? The resolved host record. Derived from `specs` when not supplied, so a
  #? caller that already resolved it does not pay for a second resolution.
  host ? (
    if specs == null
    then
      throw "context: requires either 'host' (a resolved host) or 'specs' (a raw host declaration)"
    else lix.schemas.host.mkHost specs
  ),
  inputs ? lix.inputs or {},
  ...
}: let
  data = import ./data {
    inherit lix inputs host;
  };

  core = import ./core data;
  home = import ./home {
    inherit data lix;
  };
in
  {inherit data core home;}
