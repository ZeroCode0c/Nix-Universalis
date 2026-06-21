{pkgs, ...}: {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withRuby = false;
    withPython3 = false;
  };

  xdg.configFile = {
    nvim = {
      source = ../../dots/nvim;
      recursive = true;
    };
    "micro/settings.json".text = ''
      {
        "colorscheme": "gotham"
      }
    '';
  };

  home.packages = with pkgs; [
    micro
  ];
}
