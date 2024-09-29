# _________________________________________________ Documentation<|
# |> LSD - ls replacement
# _____________________________________________________ Functions<|
function ll {
  lsd `
  --human-readable `
  --almost-all `
  --long `
  --date relative `
  --group-dirs first `
  --blocks permission `
  --blocks size `
  --blocks date `
  --blocks name
  }
  # --blocks permission, user, group, size, date, name, inode, links]
# _______________________________________________________ Aliases<|
