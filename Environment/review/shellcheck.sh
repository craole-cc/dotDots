#! /bin/sh

#==================================================
#
# SHELLCHECK
# CLI/bin/environment/app/shellcheck.sh
#
#==================================================

# _________________________________ DOCUMENTATION<|

# Shell script static analysis tool
# https://github.com/koalaman/shellcheck

# _________________________________________ LOCAL<|

# ______________________________________ EXTERNAL<|

# ______________________________________ FUNCTION<|

# --> Config Files
# Example: < function Command > => cfB vim
shck() {
	shellcheck -x "$1"
}

# _________________________________________ ALIAS<|

# __________________________________________ EXEC<|
