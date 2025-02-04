from pathlib import Path

def find_parent(name):
    # Start from the current working directory
    p = Path.cwd()

    # Return None if the current working directory does not contain the search string
    if name not in p.parts:
        return None

    # Recursively search for a parent directory with the given name
    while not p.name == name:
        try:
            p = p.resolve().parent
        except Exception:
            # If an exception is raised, return None
            return None

    # Return the path to the parent directory
    return p
