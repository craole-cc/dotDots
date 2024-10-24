# import glob
# from os.path import basename, dirname, isfile, join

# modules = glob.glob(join(dirname(__file__), "*.py"))
# __all__ = [
#     basename(f)[:-3] for f in modules if isfile(f) and not f.endswith("__init__.py")
# ]

from pathlib import Path, PurePath

__all__ = [
    PurePath(Path(f)).name[:-3]
    # for f in list(Path(__file__).parent.glob("**/*.py"))
    for f in list(Path(__file__).parent.rglob("*.py"))
    if Path.is_file(f) and not PurePath(Path(f)).name == "__init__.py"
]
# print(__all__)
