{
  pkgs,
  lib,
  ...
}: let
  accent = "#89b4fa";
  foreground = "#cdd6f4";
  muted = "#6c7086";
in {
  programs.fzf = {
    enable = true;
    enableZshIntegration = false;
    enableBashIntegration = false;
    enableFishIntegration = false;
    colors = lib.mkForce {
      "fg+" = accent;
      "bg+" = "-1";
      fg = foreground;
      bg = "-1";
      prompt = muted;
      pointer = accent;
    };
    defaultOptions = [
      "--margin=1"
      "--layout=reverse"
      "--border=none"
      "--info='hidden'"
      "-i"
      "--no-bold"
    ];
    fileWidgetOptions = [
      "--preview='bat --style=numbers --color=always --line-range :500 {}'"
      "--preview-window=right:60%:wrap"
    ];
    historyWidgetOptions = [
      "--prompt='history> '"
    ];
  };

  programs.bat = {
    enable = true;
    config = {
      pager = "less -FR";
      style = "full";
      theme = lib.mkForce "Dracula";
    };
    extraPackages = with pkgs.bat-extras; [
      batman
      batpipe
    ];
  };

  home = {
    packages = with pkgs; [
      fd
      findutils
      ripgrep
    ];
    sessionVariables = {
      MANPAGER = "sh -c 'col -bx | bat -l man -p'";
      MANROFFOPT = "-c";
    };
  };
}
