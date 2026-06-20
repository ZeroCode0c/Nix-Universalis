{
  pkgs,
  lib,
  ...
}: let
  zshnip = pkgs.callPackage ../../../pkgs/zshnip.nix {inherit pkgs;};
in {
  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      theme = "xiong-chiamiov-plus";
      plugins = ["git"];
    };
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ls = lib.mkForce "lsd";
      l = lib.mkForce "ls -l";
      la = lib.mkForce "ls -a";
      ll = lib.mkForce "ls -lh";
      lla = lib.mkForce "ls -la";
      lt = lib.mkForce "ls --tree";
      lsa = lib.mkForce "ls -lah";
      z = lib.mkForce "__zoxide_z";
      zi = lib.mkForce "__zoxide_zi";
      cp = lib.mkForce "cp -iv";
      mv = lib.mkForce "mv -iv";
      md = "mkdir -p";
      rd = "rmdir";
      nano = "micro";
      fd = lib.mkForce "fdfind";
      du = lib.mkForce "ncdu";
      h = "tldr";
      v = "nvim";
      sv = "sudo nvim";
      c = "clear";
      cls = "clear";
      _ = "sudo";
      lzg = "lazygit";
      port = "ss -tulnp | grep";
      portk = "sudo fuser -k";
    };

    initContent = ''
      [ -f /etc/zshrc ] && source /etc/zshrc
      export ZSH="$HOME/.oh-my-zsh"

      eval "$(zoxide init zsh)"

      source ${zshnip}/zshnip.zsh
      bindkey '\ej' zshnip-expand-or-edit
      bindkey '\ee' zshnip-edit-and-expand

      fzf_zoxide_widget() {
        local selected
        selected=$(zoxide query -l | fzf --multi --reverse --prompt="dirs > ")
        if [[ -n $selected ]]; then
          LBUFFER+="$selected "
          zle redisplay
        fi
      }
      zle -N fzf_zoxide_widget
      bindkey "^[z" fzf_zoxide_widget

      cpr() {
        src="$1"
        dest="$2"
        if [ -d "$src" ]; then
          rsync -ah --info=progress2 "$src/" "$dest"
        else
          rsync -ah --info=progress2 "$src" "$dest"
        fi
      }

      export PATH="$HOME/.local/bin:$PATH"
      export PATH="$HOME/.npm-global/bin:$PATH"
      export PATH="$HOME/.cargo/bin:$PATH"
      export GHC_ENVIRONMENT=-
    '';
  };

  home.packages = with pkgs; [
    lsd
    zoxide
    zshnip
  ];
}
