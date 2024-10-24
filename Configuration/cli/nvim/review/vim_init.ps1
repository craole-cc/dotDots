$pluginREPO="https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
$nvimDIR="$env:NVIM"
$pluginDIR="$nvimDIR\plugins";
$pluginRC ="$pluginDIR\plugs.vim";
$vimrc="$nvimDIR\init.vim"

$pluginDIR="$env:NVIM\plugins";

if ((Test-Path $pluginDIR)) {
  cd $nvimDIR
  Remove-Item -Path $pluginDIR -Force -Recurse
}

# Download Plugins
Write-Host "Downloading junegunn/vim-plug to manage plugins..."
mkdir $pluginDIR
touch $pluginRC
curl $pluginREPO > $pluginRC
# cd $nvimDIR
# lsd $pluginDIR
