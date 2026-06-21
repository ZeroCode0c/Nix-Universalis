{pkgs, ...}: {
  home.packages = with pkgs; [
    bc
    curl
    jq
    killall
    rsync
    tree
    unrar
    unzip
    wget
  ];
}
