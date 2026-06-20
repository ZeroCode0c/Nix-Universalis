{pkgs, ...}: {
  programs.tmux = {
    enable = true;
    mouse = true;
    shell = "${pkgs.zsh}/bin/zsh";
    prefix = "C-a";
    terminal = "tmux-256color";
    keyMode = "vi";
    baseIndex = 1;
    historyLimit = 5000;
    extraConfig = ''
      set-option -g status-position top
      set -ga terminal-overrides ",*:RGB"
      set -g renumber-windows on
      set -g set-clipboard on

      unbind %
      unbind '"'

      bind-key h select-pane -L
      bind-key j select-pane -D
      bind-key k select-pane -U
      bind-key l select-pane -R

      bind -n M-h select-pane -L
      bind -n M-j select-pane -D
      bind -n M-k select-pane -U
      bind -n M-l select-pane -R

      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
      unbind -T copy-mode-vi MouseDragEnd1Pane

      set -gq allow-passthrough on
      bind-key x kill-pane

      bind-key "|" split-window -h -c "#{pane_current_path}"
      bind-key "-" split-window -v -c "#{pane_current_path}"
      bind r source-file ~/.config/tmux/tmux.conf
      bind -r m resize-pane -Z

      bind C-y display-popup -d "#{pane_current_path}" -w 80% -h 80% -E "lazygit"
      bind C-j display-popup -E "tmux list-sessions | sed -E 's/:.*$//' | grep -v \"^$(tmux display-message -p '#S')\$\" | fzf --reverse | xargs tmux switch-client -t"
      bind C-r display-popup -d "#{pane_current_path}" -w 90% -h 90% -E "yazi"
    '';
  };
}
