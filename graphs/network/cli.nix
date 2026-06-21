{pkgs, ...}: {
  home.packages = with pkgs; [
    bandwhich
    ethtool
    mtr
    ncftp
    netop
    socat
    trippy
  ];
}
