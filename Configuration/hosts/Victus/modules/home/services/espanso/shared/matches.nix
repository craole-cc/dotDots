{
  base = {
    matches = [
      {
        trigger = ":now";
        replace = "It's {{currentdate}} {{currenttime}}";
      }
      {
        trigger = ":hello";
        replace = "line1\nline2";
      }
      {
        regex = ":hi(?P.*)\\.";
        replace = "Hi {{person}}!";
      }
    ];
  };
  global_vars = {
    global_vars = [
      {
        name = "currentdate";
        type = "date";
        params = {format = "%d/%m/%Y";};
      }
      {
        name = "currenttime";
        type = "date";
        params = {format = "%R";};
      }
    ];
  };
}
