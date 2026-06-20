{
  pkgs,
  lib,
  ...
}: let
  yaziSettings = import ../../../dots/yazi-source/yazi.nix;
  yaziKeymap = import ../../../dots/yazi-source/keymap.nix;
in {
  programs.eza = {
    enable = true;
    icons = "auto";
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
    git = true;
    extraOptions = [
      "--group-directories-first"
      "--no-quotes"
      "--header"
      "--git-ignore"
      "--classify"
      "--hyperlink"
    ];
  };

  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    shellWrapperName = "yy";
    settings = yaziSettings;
    keymap = yaziKeymap;
    plugins = {
      lazygit = pkgs.yaziPlugins.lazygit;
      full-border = pkgs.yaziPlugins.full-border;
      git = pkgs.yaziPlugins.git;
      smart-enter = pkgs.yaziPlugins.smart-enter;
    };
    initLua = ''
      require("full-border"):setup()
      require("git"):setup()
      require("smart-enter"):setup {
        open_multi = true,
      }
    '';
  };

  home.file.".config/yazi/theme.toml" = lib.mkForce {
    source = ../../../dots/yazi-source/theme.toml;
  };
}
