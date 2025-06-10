#!/bin/sh

manage_env --init --var DOTS_CFG_RUST --val "${DOTS_CFG:?}/rust"
manage_env --init --var DOTS_CFG_STARSHIP --val "${DOTS_CFG:?}/starship"
