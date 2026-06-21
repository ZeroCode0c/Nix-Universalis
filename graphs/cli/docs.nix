{pkgs, ...}: {
  programs.tealdeer = {
    enable = true;
    settings = {
      display.compact = false;
      display.use_pager = true;
      updates.auto_update = true;
    };
  };

  home.packages = with pkgs; [
    frogmouth
    mdcat
  ];
}
