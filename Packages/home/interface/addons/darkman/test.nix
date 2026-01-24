# test-darkman.nix
{pkgs, ...}: let
  toggleScript = pkgs.writeShellScript "test-toggle" ''
    #!/bin/sh
    # Test the toggle functionality

    # Create a test API file
    cat > /tmp/test-api.nix << 'EOF'
    {
      interface = {
        style = {
          theme = {
            polarity = "dark";
            accent = "teal";
            dark = "Catppuccin Frappé";
            light = "Catppuccin Latte";
          };
        };
      };
    }
    EOF

    # Test dark toggle
    echo "Testing dark mode toggle..."
    ${pkgs.sd}/bin/sd 'polarity = "(dark|light)"' 'polarity = "dark"' /tmp/test-api.nix
    echo "Result:"
    cat /tmp/test-api.nix

    # Test light toggle
    echo -e "\nTesting light mode toggle..."
    ${pkgs.sd}/bin/sd 'polarity = "(dark|light)"' 'polarity = "light"' /tmp/test-api.nix
    echo "Result:"
    cat /tmp/test-api.nix
  '';
in
  pkgs.mkShell {
    buildInputs = [toggleScript];
    shellHook = ''
      test-toggle
    '';
  }
