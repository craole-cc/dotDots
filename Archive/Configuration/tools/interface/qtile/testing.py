# Import the find_parent function from the functions.find_parent module
from functions.find_parent import *

# Find the first parent directory with the name "parent"
parent_dir = find_parent("DOTS")

if parent_dir:
    # Print the path to the parent directory
    print(parent_dir)
else:
    # Print a message if the parent directory was not found
    print("Parent directory not found")


from modules import *
# from modules.hooks import *
from modules.screens import *