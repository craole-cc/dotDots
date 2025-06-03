{
  lib,
  pkgs,
  ...
}: let
  dom = "dots";
  mod = "lib";

  inherit (lib.options) mkOption;
  inherit (lib.strings) stringLength match fileContents;

  validatePassword = password:
    if password == null
    then false
    else if stringLength password < 12
    then throw "Password must be at least 12 characters long"
    else if !(match ".*[A-Z].*" password)
    then throw "Password must contain at least one uppercase letter"
    else if !(match ".*[a-z].*" password)
    then throw "Password must contain at least one lowercase letter"
    else if !(match ".*[0-9].*" password)
    then throw "Password must contain at least one number"
    else if !(match ".*[!@#$%^&*].*" password)
    then throw "Password must contain at least one special character (!@#$%^&*)"
    else true;
in {
  options.${dom}.${mod} = {
    mkHashedPassword = mkOption {
      description = "Generates a secure password hash using Argon2";
      default = password:
        if password == null
        then null
        else if validatePassword password
        then let
          #{ Create secure temporary files
          passwordFile = pkgs.writeText "password" password;

          #{ Generate unique salt per user using high-entropy source
          salt = pkgs.runCommand "generate-salt" {} ''
            dd if=/dev/urandom bs=16 count=1 status=none > $out
          '';

          #{ Hash using Argon2id with secure parameters
          hashedPassword =
            pkgs.runCommand "hash-password"
            {
              buildInputs = [pkgs.argon2];
              inherit passwordFile;
              SALT = fileContents salt;
            }
            ''
              argon2 $(cat $passwordFile) \
                -id \
                -t 3 \
                -m 16 \
                -p 4 \
                -l 32 \
                -r > $out
            '';
        in
          fileContents hashedPassword
        else null;
    };
  };
}
