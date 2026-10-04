{
  host,
  lix,
  ...
}: let
  inherit (lix.lists) elem filter;

  #? `host.functionalities` is the resolved *record* (`{names, set, values,
  #? ...}`), not a bare list. Membership is read off its `names` list;
  #? scanning the record itself would make every test false.
  has = name: elem name host.functionalities.names;

  administrators =
    filter
    (user: user.role == "administrator")
    host.principals.all;
in {
  security = {
    sudo.extraRules = [
      {
        users = map (user: user.name) administrators;
        commands = [
          {
            command = "ALL";
            options = ["NOPASSWD"];
          }
        ];
      }
    ];

    rtkit.enable = has "audio";
  };
}
