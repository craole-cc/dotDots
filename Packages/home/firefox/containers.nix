{app, ...}: let
  pinsForce = true;
  pins = {
    "GitHub" = {
      id = "48e8a119-5a14-4826-9545-91c8e8dd3bf6";
      workspace = spaces."Rendezvous".id;
      url = "https://github.com";
      position = 101;
      isEssential = false;
    };
    "WhatsApp Web" = {
      id = "1eabb6a3-911b-4fa9-9eaf-232a3703db19";
      workspace = spaces."Rendezvous".id;
      url = "https://web.whatsapp.com/";
      position = 102;
      isEssential = false;
    };
    "Telegram Web" = {
      id = "5065293b-1c04-40ee-ba1d-99a231873864";
      url = "https://web.telegram.org/k/";
      position = 103;
      isEssential = true;
    };
  };

  containersForce = true;
  containers = {
    Shopping = {
      color = "yellow";
      icon = "dollar";
      id = 2;
    };
  };

  spacesForce = true;
  spaces = {
    "Rendezvous" = {
      id = "572910e1-4468-4832-a869-0b3a93e2f165";
      icon = "🎭";
      position = 1000;
      theme = {
        type = "gradient";
        colors = [
          {
            red = 216;
            green = 204;
            blue = 235;
            algorithm = "floating";
            type = "explicit-lightness";
          }
        ];
        opacity = 0.8;
        texture = 0.5;
      };
    };
    "Research" = {
      id = "ec287d7f-d910-4860-b400-513f269dee77";
      icon = "💌";
      position = 1001;
      theme = {
        type = "gradient";
        colors = [
          {
            red = 171;
            green = 219;
            blue = 227;
            algorithm = "floating";
            type = "explicit-lightness";
          }
        ];
        opacity = 0.2;
        texture = 0.5;
      };
    };
    "Shopping" = {
      id = "2441acc9-79b1-4afb-b582-ee88ce554ec0";
      icon = "💸";
      container = containers."Shopping".id;
      position = 1002;
    };
    "Big Big Big Problem" = {
      id = "8ed24375-68d4-4d37-ab7e-b2e121f994c1";
      icon = "😫";
      position = 1003;
    };
  };
in
  {inherit containersForce containers;}
  // (
    if app == "zen-browser"
    then {inherit pins pinsForce spaces spacesForce;}
    else {}
  )
