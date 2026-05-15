{args, ...}:
with args;
  funk.firefox.resolveModule {
    inherit inputs pkgs policies;
    variant = user.applications.browser.firefox or null;
  }
