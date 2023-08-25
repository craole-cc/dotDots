#!/usr/bin/env nu
# shellcheck shell=bash

ls --all --du --short-names | sort-by --reverse size
