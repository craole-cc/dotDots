import argparse
from pathlib import Path


def find_parent(name):
    # Start from the current working directory
    p = Path.cwd()

    # Recursively search for a parent directory with the given name
    while not p.name == name:
        p = p.resolve().parent

    # Return the path to the parent directory
    return p


if __name__ == "__main__":
    # Parse the command-line arguments
    parser = argparse.ArgumentParser(
        description="Find the first parent directory with the given name, starting from the current working directory"
    )
    parser.add_argument("name", type=str, help="name of the parent directory to find")
    args = parser.parse_args()

    # Find the parent directory and print the result
    parent_dir = find_parent(args.name)
    print(parent_dir)
