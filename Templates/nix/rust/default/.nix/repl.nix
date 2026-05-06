{
  libraries,
  packages,
}: let
  inherit (libraries.lists) filter;
  inherit (libraries.shells) mkTools;
  inherit (libraries.packages) resolveBin;

  packageName = pkg:
    pkg.meta.name or pkg.name or pkg.pname or null;

  inspectList = packageList: let
    findAll = name:
      filter
        (pkg: packageName pkg == name)
        packageList;

    hasPkg = name:
      findAll name != [];

    findPkg = name: let
      matches = findAll name;
    in
      if matches == []
      then throw "repl.inspectList.findPkg: package not found: '${name}'"
      else builtins.head matches;

    cmdPath = name:
      resolveBin {
        inherit name;
        drv = findPkg name;
      };

    cmdText = name:
      (findPkg name).text or null;

    cmdInfo = name: let
      pkg = findPkg name;
    in {
      inherit name pkg;
      packageName = packageName pkg;
      path = resolveBin {
        inherit name;
        drv = pkg;
      };
      text = pkg.text or null;
      meta = pkg.meta or {};
    };

    cmdTexts = names:
      map
        (name: {
          inherit name;
          text = cmdText name;
        })
        names;
  in {
    inherit
      packageList
      findAll
      hasPkg
      findPkg
      cmdPath
      cmdText
      cmdInfo
      cmdTexts
      ;
  };

  inspectAttrs = packageSet: let
    hasPkg = name:
      packageSet ? ${name};

    findPkg = name:
      if hasPkg name
      then packageSet.${name}
      else throw "repl.inspectAttrs.findPkg: package not found: '${name}'";

    cmdPath = name:
      resolveBin {
        inherit name;
        drv = findPkg name;
      };

    cmdText = name:
      (findPkg name).text or null;

    cmdInfo = name: let
      pkg = findPkg name;
    in {
      inherit name pkg;
      packageName = packageName pkg;
      path = resolveBin {
        inherit name;
        drv = pkg;
      };
      text = pkg.text or null;
      meta = pkg.meta or {};
    };
  in {
    inherit
      hasPkg
      findPkg
      cmdPath
      cmdText
      cmdInfo
      ;
  };

  tools = mkTools {pkgs = packages;};
in {
  inherit
    inspectList
    inspectAttrs
    ;

  tools = inspectList tools.packages;
  pkgs = inspectAttrs packages;
}
