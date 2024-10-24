# _________________________________________________ Documentation<|
# |> System
$URL = "https://gitlab.com/"
$KEY = "GitLab_Key"
$TAG = "ssh,ci"
$RUN = "Test"
# __________________________________________________________ PATH<|

# $env:Path += ";C:\gitlab-runner"
Set-Alias glr gitlab-runner
function glrreg {
  gitlab-runner register `
  --url $URL `
  --registration-token $KEY `
  --tag-list $TAG `
  --name $RUN
}
function glrsta { gitlab-runner status }
function glrstp { gitlab-runner stop }
function glrstr { gitlab-runner start }
function glrl { gitlab-runner list }
function glrhc { gitlab-runner health-check }
function glrver { gitlab-runner --version }

# DotArch
function gpsA { git push -u "https://gitlab.com/Craole/dotarch.git" master }
function gpsW { git push -u "https://gitlab.com/Craole/dotwin10.git" master }
function gs { git status }
function gau { git add --update }
function gaa { git add --all }
function gcm { git commit -m $args }
function gcl { git clone $args }
function gitin { git init }
function glg { git log }
function gf { git fetch $args }
function gpl { git pull $args }
function gm { git merge $args }

function dotgit { git --git-dir=E:/dots --work-tree=E:/Dotfiles }