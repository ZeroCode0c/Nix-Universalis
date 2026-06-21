{pkgs, ...}: {
  home.packages = with pkgs; [
    kitty
    zellij
  ];

  xdg.configFile = {
    kitty = {
      source = ../../dots/kitty;
      recursive = true;
    };
    "zellij/config.kdl".text = ''
      default_shell "zsh"
      pane_frames false
      simplified_ui true
      default_layout "compact"

      keybinds {
        normal {
          bind "Ctrl h" { MoveFocus "Left"; }
          bind "Ctrl j" { MoveFocus "Down"; }
          bind "Ctrl k" { MoveFocus "Up"; }
          bind "Ctrl l" { MoveFocus "Right"; }
        }
      }
    '';
  };
}
