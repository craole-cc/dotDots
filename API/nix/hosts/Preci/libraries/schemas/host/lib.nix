{
  lix,
  resolve,
  ...
}: {
  mkHost = {args}: let
    resolved = resolve args.host;
    principals = lix.schemas.mkUsers {
      inherit args;
      principals = resolved.principals;
    };
  in
    resolved // {inherit principals;};
}
