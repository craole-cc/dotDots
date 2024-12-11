#!/usr/bin/python

# Python program to explain os.path.expandvars() method 

# importing os.path module 
import os.path

# Path
path = "$DOTS"

# Expand the environment variables
# with their corresponding 
# value in the given path
exp_var = os.path.expandvars(path)


# Print the given path with
# environment variables expanded
print(exp_var)


# Change the value of 
# Environment variable 'HOME'

os.environ["HOME"] = "/home/GeeksForGeeks"

# Path
path = "$HOME/Documents/file.txt"

# Expand the environment variables
# with their corresponding 
# value in the given path
exp_var = os.path.expandvars(path)

# Print the given path with
# environment variables expanded
print(exp_var)


# Create an environment variable
os.environ["USER"] = "ihritik"

# Path
path = "/home/${USER}/file.txt"

# Expand the environment variables
# with their corresponding 
# value in the given path
exp_var = os.path.expandvars(path)

# Print the given path with
# environment variables expanded
print(exp_var)


# In the above example,
# os.path.expandvars() method replaced 
# the environment variable 'HOME' and 'USER'
# with their corresponding values