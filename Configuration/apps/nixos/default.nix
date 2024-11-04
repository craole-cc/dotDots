{
  imports = [
    ./apps
    ./hosts
    ./libraries
    ./services
    ./users
  ];

  # paths = {
  #   src = ./Configuration/apps/nixos;
  #   core = with paths.core; {
  #     src = paths.src + "/core";
  #     lib = src + "/libraries";
  #     opt = src + "/options";
  #     cfg = src + "/configurations";
  #   };
  #   home = with paths.home; {
  #     src = paths.src + "/home";
  #     lib = src + "/libraries";
  #     opt = src + "/options";
  #     cfg = src + "/configurations";
  #   };
  # };

  # mods = {
  #   core =
  #     (with paths.core; [
  #       lib
  #       opt
  #     ])
  #     ++ [
  #       home-manager
  #       {
  #         home-manager = {
  #           backupFileExtension = "BaC";
  #           useGlobalPkgs = true;
  #           useUserPackages = true;
  #         };
  #       }
  #     ];
  #   home = with paths.home; [
  #     lib
  #     opt
  #   ];
  # };
}
