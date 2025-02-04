import argparse
import random
from pathlib import Path


def main():
    # @ Parse the command-line arguments
    parser = argparse.ArgumentParser(
        description="Selects a random image from the specified folder path recursively.",
    )
    parser.add_argument(
        "folder_path",
        help="path of the directory containing the image files",
    )
    parser.add_argument(
        "-d",
        "--default",
        default=None,
        help="default value to return if no image is found",
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="verbose output",
    )
    parser.add_argument(
        "--version",
        action="version",
        version="get_random_image 1.0",
    )
    args = parser.parse_args()

    # @ Call the get_random_image function with the specified arguments
    random_image_path = get_random_image(args.folder_path, args.default, args.verbose)

    # @ Print the output
    print(random_image_path)


def get_random_image(folder_path, default=None, verbose=False):
    """
    Selects a random image from the specified folder path recursively.

    Args:
        folder_path (str or Path): path of the directory
        default (any): default value to return if no image is found (default: None)
        verbose (bool): if True, prints verbose output (default: False)

    Returns:
        str: the path of the selected image file or the default value
    """
    # @ Convert folder_path to Path object
    folder_path = Path(folder_path)

    # @ Get a list of all image files recursively
    image_files = list(folder_path.glob("**/*.*"))
    image_files = [
        f
        for f in image_files
        if f.suffix.lower()
        in [
            ".jpg",
            ".png",
            ".tiff",
            ".svg",
            ".jpeg",
            ".bmp",
            ".gif",
        ]
    ]

    # @ Select a random image file
    if image_files:
        random_image_path = random.choice(image_files)
        message = f"Found {len(image_files)} image files.\nSelected image: {random_image_path}"
    else:
        random_image_path = default
        message = "No image files found."

    # @ Print verbose message if verbose is True
    if verbose:
        print(message)

    return str(random_image_path)


if __name__ == "__main__":
    main()
