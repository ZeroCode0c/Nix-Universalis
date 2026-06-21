{pkgs, ...}: {
  home.packages = with pkgs; [
    atop
    caligula
    glances
  ];
}
