{
  imports = [
    ./base
    ./environment
    ./interface
    ./libraries
    ./packages
    ./security
    ./services
    ./users
  ];

  config.DOTS = {
    interface.manager = "xfce";
  };
}
