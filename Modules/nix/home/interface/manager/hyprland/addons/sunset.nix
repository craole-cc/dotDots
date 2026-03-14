{
  hyprsunset = {
    enable = true;
    settings = {
      max-gamma = 150;

      profile = [
        {
          time = "7:30";
          identity = true;
        }
        {
          time = "21:00";
          temperature = 5000;
          gamma = 0.8;
        }
      ];
    };
    # transitions = {
    #   sunrise = {
    #     calendar = "*-*-* 06:00:00";
    #     requests = [
    #       ["temperature" "6500"]
    #       ["gamma 100"]
    #     ];
    #   };
    #   sunset = {
    #     calendar = "*-*-* 19:00:00";
    #     requests = [
    #       ["temperature" "3500"]
    #     ];
    #   };
    # };
  };
}
