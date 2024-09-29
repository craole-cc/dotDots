#This file contains commands and instructions for installing Linux distributions on Windows 10 through WSL

# 0. If you are testing this on a VM then you have to enable nested virtualization for that machine. This is how to do it on a Hyper-V host:
# Set-VMProcessor -VMName <VMName> -ExposeVirtualizationExtensions $true
# Get-VMNetworkAdapter -VMName <VMName> | Set-VMNetworkAdapter -MacAddressSpoofing On

# 1. First we need to enable the WSL optional feature and Hyper-V and restart the computer
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
Restart-Computer

# 2. Create a folder where the Linux distribution will be placed and executed from
New-Item C:\Distros -ItemType Directory
Set-Location C:\Distros

# 3. Use one of the commands below to download the distribution of your choice (I will go with the first one)
#  Ubuntu 18.04
Invoke-WebRequest -Uri https://aka.ms/wsl-ubuntu-1804 -OutFile .\Ubuntu.appx -UseBasicParsing
#  Ubuntu 16.04
Invoke-WebRequest -Uri https://aka.ms/wsl-ubuntu-1604 -OutFile .\Ubuntu.appx -UseBasicParsing
#  Debian GNU Linux
Invoke-WebRequest -Uri https://aka.ms/wsl-debian-gnulinux -OutFile .\Debian.appx -UseBasicParsing
#  Kali Linux
Invoke-WebRequest -Uri https://aka.ms/wsl-kali-linux -OutFile .\Kali.appx -UseBasicParsing
#  OpenSUSE
Invoke-WebRequest -Uri https://aka.ms/wsl-opensuse-42 -OutFile .\SUSE.appx -UseBasicParsing
#  SLES
Invoke-WebRequest -Uri https://aka.ms/wsl-sles-12 -OutFile .\SLES.appx -UseBasicParsing
#  Fedora Remix for WSL
#  Please check this link to get the link for the latest release: https://github.com/WhitewaterFoundry/Fedora-Remix-for-WSL/releases
#  At the time of making the video I got this error: 0x80070002 when trying to use the Fedora distribution and did not find a way to fix it
Invoke-WebRequest -Uri https://github.com/WhitewaterFoundry/Fedora-Remix-for-WSL/releases/download/31.5.0/Fedora-Remix-for-WSL_31.5.0.0_x64_arm64.appxbundle -OutFile .\Fedora.appxbundle -UseBasicParsing
Rename-Item .\Fedora.appxbundle Fedora.zip
Expand-Archive .\Fedora.zip
Copy-Item .\Fedora\Fedora-Remix-for-WSL_31.5.0.0_x64.appx .\Fedora.appx
Remove-Item .\Fedora -Recurse -Force
Remove-Item .\Fedora.zip

# 4. Rename and extract the distro file
Rename-Item .\Ubuntu.appx .\Ubuntu.zip
Expand-Archive .\Ubuntu.zip

# 5. Clean up
Remove-Item .\Ubuntu.zip

# 6. Download and install update for the WSL Linux Kernel
Invoke-WebRequest -Uri https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi -OutFile .\wsl_update_x64.msi -UseBasicParsing
Start-Process -FilePath 'msiexec' -ArgumentList '/i C:\Distros\wsl_update_x64.msi','/q' -Wait

# 7. Set the default WSL version to 2
wsl --set-default-version 2

# 8. Install the Linux distribution
#  Make sure you do not forget the password that you will enter at the prompt as that is your root password
Set-Location .\Ubuntu
.\ubuntu1804.exe

#To run the WSL shell after the installation just run one of the following
wsl.exe
bash.exe
ubuntu1804.exe #from the distro install directory

#List all distributions with their WSL version
wsl --list --verbose

#For an existing distribution that is version 1 you can convert it to version 2
# wsl --set-version <distribution name> 2