let
  projects = (import ../../paths).stems.home.projects;
in
  {
    imports = [./config];
    description = "Craig 'Craole' Cole";
    password = "$6$2o3rjHVZgXEuyZ97$PtmQa1PIOmKb6dAwZ0mZJUulAkJoCfj.qjJHgtusfVnIIsHmENcA7q8PV9I2PveOwdEdFWwMBgLu3a5HZavXC1";
    paths = rec {
      stems.home.prj.cc = projects ++ ["craole-cc"];
      pics = "home:Pictures";
      dlds = "home:Downloads";
      avatars.session = pics + "/avatar.jpg";
      wallpapers = "home:Pictures/Wallpapers";
    };
  }
  // (import ./interface)
  // (import ./packages)
  // (import ./skills)
