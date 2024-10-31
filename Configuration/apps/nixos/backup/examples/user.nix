{ config, ... }:
{
  config.dots.users.tempuser = {
    description = "Full Name of the user";
    uid = null; # use null to let the system assign a uid or use an explicit integer between 1000 and 59999
    hashedPassword = "$y$j9T$2/KP4Wdc085m.udldFeHA0$C8K1uEH1hBwM0SHXg5l2Rnvy3jGEnq/p0MN7O7ZIXw3";
  };
}
