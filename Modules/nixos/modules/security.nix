{ alpha, ... }:
{
  security.sudo = {
    execWheelOnly = true;
    extraRules = [
      {
        users = [ alpha ];
        commands = [
          {
            command = "ALL";
            options = [
              "SETENV"
              "NOPASSWD"
            ];
          }
        ];
      }
    ];
  };
}
