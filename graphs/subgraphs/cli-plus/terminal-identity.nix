{pkgs, ...}: {
  home.packages = with pkgs; [
    fastfetch
    onefetch
    starship
  ];
}
