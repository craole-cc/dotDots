{ config, ... }:
let
  inherit (config.DOTS.Libraries.fetchers) githubEmail;
in
{
  DOTS.Users.qyatt = {
    description = "Kezia 'Qyatt' Fullerton";
    apps = {

      # git = rec {
      #   name = "Qyatt876";
      #   email = githubEmail {
      #     user = name;
      #     sha256 = "BJYJ4DWou7bJnWqkTDmd5rb4YZngx9uYdQU0epLDqhQ=";
      #   };
      # };

      firefox = {
        isPrimary = true;
        edition = "dev";
      };
    };
  };
}
