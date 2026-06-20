{pkgs, ...}: {
  home.packages = with pkgs; [
    erdtree
    hyperfine
    lstr
    pik
    tokei
  ];
}
