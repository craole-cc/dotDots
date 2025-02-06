#!/bin/sh

#@ Paths
DOC_PATH="${DOTS}/Documentation/README.md"
ROOT_README="README.md"

#@ Generate Root README
cat <<EOF >"$ROOT_README"
# dotDOTS

dotDOTS is a collection of my personal tools and configuration files designed to be portable and efficient across various systems and environments.

For full documentation, visit [Documentation/README.md](./Documentation/README.md).

## Quick Links

- [Installation](./Documentation/README.md#installation)
- [Key Features](./Documentation/README.md#key-features)
- [Contributing](./Documentation/README.md#contributing)

EOF

echo "Root README generated successfully."
