#!/bin/sh

Turbo() {
  repo="$1"
  pnpm dlx create-turbo@latest "$repo" \
    --use-pnpm

  cd "$repo" || return

  #? Initialize Turborepo
  pnpm dlx turbo login
  pnpm dlx turbo link

  #? Initialize Git
  git init

  #? Install Husky and Lint-staged
  pnpm add husky lint-staged \
    --ignore-workspace-root-check \
    --save-dev

  #? Initialize Husky
  npm set-script prepare "husky install"
  pnpm prepare
  pnpm dlx husky add .husky/pre-commit \
    "pnpm test && pnpm dlx lint-staged"

  #? Add Tailwindand config
  packagesDIR="$(git rev-parse --show-toplevel)/packages"
  tailwindDIR="$prJS/Templates/turborepo/tailwind"
  cd "$packagesDIR" || return
  cp --recursive --force "$tailwindDIR" "$packagesDIR"
  pnpm install
  pnpm up --latest

  code .
}

# "clean": "rm -rf .turbo && rm -rf node_modules"