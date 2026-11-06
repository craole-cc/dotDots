{mkSource, ...}: {
  khal = mkSource {
    categories = ["communication"];
    description = "terminal calendar";
    # The locked Sphinx hook reads a scalar even with structured attributes.
    transform = package:
      package.overridePythonAttrs (_previous: {
        sphinxBuilders = "html man";
      });
  };

  vdirsyncer = mkSource {
    categories = ["communication"];
    description = "CalDAV calendar synchronisation";
    target = "vdirsyncer";
    exe = "vdirsyncer";
  };

  thunderbird = mkSource {
    categories = ["communication"];
    description = "email and calendar client";
    target = "thunderbird";
    exe = "thunderbird";
  };

  # TODO: WHY, I dont think i want this
  python3 = mkSource {
    categories = ["communication"];
    description = "Python runtime";
    target = "python3";
    exe = "python3";
  };
}
