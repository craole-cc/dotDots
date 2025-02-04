from pathlib import Path, PurePath, PurePosixPath

# import pathlib

QTILE_HOME = Path.home() / "Dotfiles/Config/tools/interface/qtile"
QTILE_MODS = QTILE_HOME / "modules"
DECLARATIONS = QTILE_MODS / "declarations.py"
TESTS = QTILE_HOME / "tests"
MODULES = QTILE_HOME / "modules"
SCRIPTS = QTILE_HOME / "scripts"
RESOURCES = QTILE_HOME / "resources"

print(f"QTILE_HOME: {QTILE_HOME}")
print(f"QTILE_MODS: {QTILE_MODS}")
list(QTILE_MODS.glob("**/*.py"))

# p = Path('.')
# [x for x in p.iterdir() if x.is_dir()]

# print(sorted(Path(QTILE_MODS).glob("*.py")))

# importing the importlib.util module
from importlib import import_module

# # declarations
# spec = importlib.util.spec_from_file_location("config", QTILE_MODS / "declarations.py" )
# declarations = importlib.util.module_from_spec(spec)
# spec.loader.exec_module(declarations)

# # hooks
# spec = importlib.util.spec_from_file_location("config", QTILE_MODS / "hooks.py" )
# hooks = importlib.util.module_from_spec(spec)
# spec.loader.exec_module(hooks)

# # hooks
# spec = importlib.util.spec_from_file_location("config", QTILE_MODS / "hooks.py" )
# hooks = importlib.util.module_from_spec(spec)
# spec.loader.exec_module(hooks)
from pathlib import Path

INIT = Path.home() / "Dotfiles/Config/tools/interface/qtile/config.py"
exec(open(INIT).read())


from modules import *
