{host, lix, ...}: let
  administrators = lix.lists.filter
    (user: user.role == "administrator")
    host.principals.all;
in {
  security = {
    sudo.extraRules = [
      {
        users = lix.lists.map (user: user.name) administrators;
        commands = [{
          command = "ALL";
          options = ["NOPASSWD"];
        }];
      }
    ];

    rtkit.enable = lix.lists.elem "audio" host.functionalities;
  };
}
