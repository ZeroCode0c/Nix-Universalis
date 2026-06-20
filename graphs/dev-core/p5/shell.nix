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

      fzf_snippets_widget() {
        local default_file=~/WS/bin/SaveText.sh
        local file="$default_file"
        local left right token candidate selected result key
        local -a file_stack

        fzf_snippets_resolve_file() {
          local raw="$1"
          local resolved

          while [[ "$raw" == [[:space:]]* ]]; do raw="''${raw#[[:space:]]}"; done
          while [[ "$raw" == *[[:space:]] ]]; do raw="''${raw%[[:space:]]}"; done
          [[ "$raw" == nvim\ * ]] && raw="''${raw#nvim }"
          raw="''${raw%%[[:space:]]*}"
          raw="''${raw%\"}"
          raw="''${raw#\"}"
          raw="''${raw%\'}"
          raw="''${raw#\'}"

          [[ -z $raw ]] && return 1

          if [[ "$raw" == /* ]]; then
            resolved="$raw"
          elif [[ "$raw" == \~/* ]]; then
            resolved="$HOME/''${raw[3,-1]}"
          else
            resolved="$PWD/$raw"
          fi

          [[ -f "$resolved" ]] || return 1
          print -r -- "$resolved"
        }

        fzf_snippets_without_comment() {
          local line="$1"

          [[ "$line" == \#* ]] && return 0
          line="''${line%% #*}"
          while [[ "$line" == *[[:space:]] ]]; do line="''${line%[[:space:]]}"; done
          print -r -- "$line"
        }

        fzf_snippets_ensure_entry_file() {
          local entry_file="$1"
          local entry_dir="''${entry_file:h}"

          if [[ -e "$entry_file" && ! -f "$entry_file" ]]; then
            zle -M "Alt+w: path exists but is not a file: $entry_file"
            return 1
          fi

          if [[ ! -d "$entry_dir" ]]; then
            mkdir -p -- "$entry_dir" || {
              zle -M "Alt+w: could not create directory: $entry_dir"
              return 1
            }
          fi

          if [[ ! -f "$entry_file" ]]; then
            {
              print -r -- "# Snippets for Alt+w"
              print -r -- "# Add one snippet per line."
              print -r -- "# Use: nvim /path/to/another/file and press Alt+w to enter it."
            } > "$entry_file" || {
              zle -M "Alt+w: could not create file: $entry_file"
              return 1
            }
          fi
        }

        fzf_snippets_ensure_entry_file "$default_file" || return 1

        left="$LBUFFER"
        right="$RBUFFER"
        while [[ "$left" == *[[:space:]] ]]; do left="''${left%[[:space:]]}"; done
        while [[ "$right" == [[:space:]]* ]]; do right="''${right#[[:space:]]}"; done

        token="''${left##*[[:space:]]}"
        token+="''${right%%[[:space:]]*}"
        candidate="$(fzf_snippets_resolve_file "$token")" && file="$candidate"

        while true; do
          if [[ ! -f $file ]]; then
            zle -M "Alt+w: file not found: $file"
            return 1
          fi

          result=$(
            {
              print -r -- "nvim $file"
              cat "$file"
            } | fzf --expect=alt-w,alt-enter,alt-bs,alt-bspace,alt-backspace --reverse --prompt="file $file > "
          )
          [[ -z $result ]] && return 0

          key="''${result%%$'\n'*}"
          selected="''${result#*$'\n'}"
          [[ "$result" != *$'\n'* ]] && selected="$result"

          if [[ $key == alt-w ]]; then
            if candidate="$(fzf_snippets_resolve_file "$selected")"; then
              file_stack+=("$file")
              file="$candidate"
            fi
            continue
          fi

          if [[ $key == alt-bs || $key == alt-bspace || $key == alt-backspace ]]; then
            if (( ''${#file_stack[@]} > 0 )); then
              file="''${file_stack[-1]}"
              file_stack[-1]=()
            fi
            continue
          fi

          if [[ $key != alt-enter ]]; then
            selected="$(fzf_snippets_without_comment "$selected")"
          fi

          if [[ -n $selected ]]; then
            LBUFFER+="$selected "
            zle redisplay
          fi
          return 0
        done
      }
      zle -N fzf_snippets_widget
      bindkey "^[w" fzf_snippets_widget

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
