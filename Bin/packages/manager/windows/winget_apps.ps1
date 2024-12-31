# requires -RunAsAdministrator
#requires -Version 5.1

<#
.SYNOPSIS
    Bulk installer script for Windows applications using winget.

.DESCRIPTION
    This script installs multiple applications using winget package manager.
    Applications are categorized for better organization and maintenance.
    After installation, it runs topgrade to ensure everything is up to date.

.PARAMETER WhatIf
    If specified, shows what applications would be installed without actually installing them.

.EXAMPLE
    .\install_apps.ps1
    Installs all applications

.EXAMPLE
    .\install_apps.ps1 -WhatIf
    Shows what would be installed without actually installing

.NOTES
    - Requires winget to be installed
    - Requires administrative privileges
    - Uses topgrade for updates after installation
#>

param([switch] $WhatIf)

#region Functions
function Install-Applications {
    param (
        [array]$apps,
        [switch]$WhatIf
    )
    
    foreach ($app in $apps) {
        Write-Host ("-" * 80) -ForegroundColor Gray
        
        if ($WhatIf) {
            Write-Host "Would install: $app" -ForegroundColor Cyan
        }
        else {
            Write-Host "Installing: $app" -ForegroundColor Yellow
            try {
                winget install --id $app --silent --accept-package-agreements --accept-source-agreements
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "Successfully installed: $app" -ForegroundColor Green
                }
                # else {
                #     Write-Host "Failed to install: $app (Exit code: $LASTEXITCODE)" -ForegroundColor Red
                # }
            }
            catch {
                Write-Host "Error installing $app`: $_" -ForegroundColor Red
            }
        }
    }
}

function Update-AllPackages {
    Write-Host "`nRunning topgrade to ensure everything is up to date..." -ForegroundColor Yellow
    topgrade --cleanup --no-retry --yes --disable microsoft_store
}

function Main {
    param([switch]$WhatIf)

    # Verify winget is available
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Error "Winget is not installed. Please install it from the Microsoft Store."
        exit 1
    }

    # Combine all app arrays
    $allApps = $systemUtils + $devTools + $mediaApps + $communicationApps + $creativeApps + $internetApps

    # Install apps
    Install-Applications -apps $allApps -WhatIf:$WhatIf

    # Run updates if not in WhatIf mode
    if (-not $WhatIf) {
        Update-AllPackages
    }
}
#endregion

#region System Utilities & Monitoring
$systemUtils = @(
    "Microsoft.PowerToys", # Power user tools
    "Armin2208.WindowsAutoNightMode", # Auto dark/light mode
    "REALiX.HWiNFO", # Hardware info
    "ALCPU.CoreTemp", # CPU temperature monitor
    "CPUID.HWMonitor", # Hardware monitoring
    "Maxon.CinebenchR23", # CPU benchmark
    'Unigine.HeavenBenchmark', # GPU benchmark
    "Geeks3D.FurMark", # GPU benchmark
    "7zip.7zip", # File compression
    "voidtools.Everything", # Fast file search
    "WinDirStat.WinDirStat", # Disk usage analyzer
    "Starship.Starship", # Cross-shell prompt
    "dbrgn.tealdeer", # TL;DR for man pages
    "printfn.fend", # Terminal calculator
    "ajeetdsouza.zoxide", # Smarter cd command
    "spacedrive.Spacedrive", # File management
    "bootandy.dust", # Disk usage analyzer
    "Byron.dua-cli", # Disk usage analyzer
    "eza-community.eza", # Modern ls replacement
    "Y2Z.Monolith", # Website archiver
    "Clement.bottom", # System monitor
    "dalance.procs", # Process viewer
    "IObit.Uninstaller", # Software uninstaller
    "IObit.AdvancedSystemCare", # System utility
    "IObit.DriverBooster", # Driver updater
    "IObit.IObitSoftwareUpdater", # Software updater
    "IObit.MalwareFighter", # Antivirus
    "IObit.SmartDefrag", # Disk defragmenter
    "CrystalDewWorld.CrystalDiskInfo.ShizukuEdition", # Drive health monitor
    "CrystalDewWorld.CrystalDiskMark.ShizukuEdition", # Disk benchmark
    "Olivia.VIA", # Keyboard configurator
    "Valve.Steam"
    "topgrade-rs.topgrade" # System updater
)
#endregion

#region Development Tools
$devTools = @(
    "Git.Git", # Version control
    "Microsoft.VisualStudio.2022.BuildTools", # VS build tools
    "Microsoft.VisualStudioCode.Insiders", # Code editor
    "Microsoft.VisualStudioCode.Insiders.CLI", # VSCode CLI
    "Microsoft.WindowsTerminalPreview", # Terminal emulator
    "Codeium.Windsurf", # AI coding assistant
    "sxyazi.yazi", # Terminal file manager
    "Helix.Helix", # Modal text editor
    "Rustlang.mdBook", # Documentation generator
    "Rustlang.Rustup", # Rust toolchain
    "Rye.Rye", # Python toolchain
    "sharkdp.bat", # Cat clone
    "sharkdp.fd", # Find alternative
    "sharkdp.ripgrep", # Fast grep
    "sharkdp.hyperfine", # Benchmark tool
    "chmln.sd", # Sed alternative
    "dandavison.delta", # Git diff tool
    "uutils.coreutils", # Unix tools
    "Casey.Just", # Command runner
    "jqlang.jq", # JSON processor
    "XAMPPRocky.Tokei", # Code statistics
    "Wilfred.difftastic", # Structural diff
    "pnpm.pnpm", # Package manager
    "Yarn.Yarn", # Package manager
    "OpenJS.NodeJS"                                         # JavaScript runtime
)
#endregion

#region Media & Entertainment
$mediaApps = @(
    "johnsadventures.JohnsBackgroundSwitcher", # Wallpaper manager
    "VentisMedia.MediaMonkey.5", # Media library manager
    "Daum.PotPlayer", # Video player
    "PrestonN.FreeTube" # YouTube client
)
#endregion

#region Communication & Social
$communicationApps = @(
    "9NBDXK71NK08", # WhatsApp
    "Microsoft.Skype" # Skype
)
#endregion

#region Creative & Productivity
$creativeApps = @(
    "Notion.Notion", # Note-taking
    "Canva.Canva", # Design tool
    "darktable.darktable", # RAW photo editor
    "krita.krita", # Digital painting
    "BlenderFoundation.Blender", # 3D modeling  
    "inkscape.inkscape", # Vector graphics
    "OBSProject.OBS" # Streaming/recording
)
#endregion

#region Internet & Downloads
$internetApps = @(
    "c0re100.qBittorrent-Enhanced-Edition", # Torrent client
    "Brave.Brave.Nightly", # Web browser
    "Bitwarden.Bitwarden", # Password manager
    "ProtonTechnologies.ProtonVPN", # VPN client
    "Ookla.Speedtest.CLI" # Speed test tool
)
#endregion

# Run the main function
Main -WhatIf:$WhatIf