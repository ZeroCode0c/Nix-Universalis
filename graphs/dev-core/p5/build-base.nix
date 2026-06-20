{pkgs, ...}: {
  home.packages = with pkgs; [
    cmake
    gcc
    gnumake
    openssl
  ];
}
