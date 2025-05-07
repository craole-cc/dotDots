# _________________________________________________ Documentation<|
# |> YouTube via mpv, youtubedl and ffmpeg
# _____________________________________________________ Functions<|

  function yt {mpv $args}
  function yta {mpv --no-video $args}
  function mols {mpv --list-options | rg -v deprecated | rg $args | less}
  function mental {
    Set-Location F:\Videos\TV\The_Mentalist
    lsd
  }
