{pkgs, ...}: {
  home.packages = with pkgs; [
    ctop
    distrobox
    lazydocker
  ];
}
