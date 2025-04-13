{
  config,
  host,
  ...
}:
{
  config = {
    environment = {
      variables = {
        DOTS = host.flake or "/home/craole/.dots";
        DOTS_STORE = config.dots.outPath or null;
      };

      # Session variables (sourced by login shells)
      sessionVariables = {
        inherit (config.environment.variables)
          DOTS
          DOTS_STORE
          ;
      };
    };
  };
}
