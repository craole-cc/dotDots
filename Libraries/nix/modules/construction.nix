      wantsPlasma = mkWants "plasma" desktopEnvironments;
    };

    ctx = {
      inherit
        config
        derived
        dom
        kind
        mod
        name
        resolved
        sub
        top
        ;
      inherit (derived) path cfg;
    };
  in
    ctx // {inherit ctx;};
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.store;
  }