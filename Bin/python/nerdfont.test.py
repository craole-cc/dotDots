#!/usr/bin/env python3
"""Test Nerd Font rendering in your terminal."""

# Test categories
NUMERALS = "0123456789"
SIMILAR = "oO08 iIlL1 g9qCGQ 8%& <([{}])> .,;: -_="
DIACRITICS = "â é ù ï ø ç Ã Ē Æ œ"
LIGATURES = [
    "!= !== == === <= >= -> => || && ++ -- ** // /* */ := :: ;; =>= ",
    "if (a != b && c >= d) { foo->bar(); arr[i]++; }",
    "const lambda = (x) => x * x; // Arrow function",
    "a === b && b !== c || d <= e && f >= g"
]
EXTENDED_LIGATURES = [
    ">>> <<= >>= <== ==> <=> <||> <&&> <**> <++> <--> <~~> <==>",
    "foo <<= 1; bar >>= 2; baz <== qux; quux ==> corge;"
]
NERD_ICONS = {
    # Development
    "dev": "\uf013",        # Gear
    "git": "\uf1d3",        # Git
    "github": "\uf408",     # GitHub
    "gitlab": "\uf296",     # GitLab
    "branch": "\uf418",     # Git Branch
    "commit": "\uf417",     # Git Commit

    # Files & Folders
    "folder": "\uf114",     # Folder
    "file": "\uf15b",       # File
    "config": "\ue615",     # Config file
    "lock": "\uf023",       # Lock

    # Status & Notifications
    "warning": "\uf071",    # Warning
    "error": "\uf057",      # Error
    "info": "\uf05a",       # Info
    "check": "\uf00c",      # Check
    "cross": "\uf00d",      # Cross

    # Programming Languages
    "python": "\uf81f",     # Python
    "javascript": "\ue60c",  # JavaScript
    "typescript": "\ue628",  # TypeScript
    "rust": "\ue7a8",       # Rust
    "go": "\ue626",         # Go
    "docker": "\uf308",     # Docker

    # Editors & Tools
    "vscode": "\ue70c",     # VS Code
    "vim": "\ue62b",        # Vim
    "terminal": "\uf120",   # Terminal
    "powershell": "\ue795", # PowerShell

    # System & Hardware
    "windows": "\ue70f",    # Windows
    "linux": "\uf31a",      # Linux
    "apple": "\uf302",      # Apple
    "cpu": "\uf85a",        # CPU
    "ram": "\uf85a",        # RAM

    # Media & Communication
    "music": "\uf001",      # Music
    "video": "\uf03d",      # Video
    "email": "\uf0e0",      # Email
    "wifi": "\uf1eb",       # WiFi
}

def test_font_rendering():
    """Test various character sets and Nerd Font icons."""
    print("\n=== Nerd Font Rendering Test ===")
    print("=" * 40)

    print("\nNumerals:")
    print(NUMERALS)

    print("\nSimilar Characters:")
    print(SIMILAR)

    print("\nDiacritics:")
    print(DIACRITICS)

    print("\n=== Nerd Font Icons ===")
    max_key_length = max(len(k) for k in NERD_ICONS.keys())
    for name, icon in NERD_ICONS.items():
        print(f"{name:<{max_key_length}} : {icon}")

    print("\n=== Quick Icon Reference ===")
    quick_icons = [
        f"Terminal: {NERD_ICONS['terminal']}",
        f"Music: {NERD_ICONS['music']}",
        f"Folder: {NERD_ICONS['folder']}",
        f"Dev: {NERD_ICONS['dev']}",
        f"Python: {NERD_ICONS['python']}",
        f"Git: {NERD_ICONS['git']}",
        f"Warning: {NERD_ICONS['warning']}"
    ]
    print(" | ".join(quick_icons))

    print("\n=== Programming Ligatures Test ===")
    for line in LIGATURES:
        print(line)

    print("\n=== Extended Ligatures Test ===")
    for line in EXTENDED_LIGATURES:
        print(line)

    print("\n=== Test Complete ===")
    print("If you see:")
    print("1. Nerd Font glyphs rendered properly above")
    print("2. Ligatures combined into single symbols")
    print("3. Icons displayed correctly")
    print("Then your font and terminal support Nerd Fonts and ligatures properly.")

if __name__ == "__main__":
    test_font_rendering()
    input("\nPress Enter to exit...")
