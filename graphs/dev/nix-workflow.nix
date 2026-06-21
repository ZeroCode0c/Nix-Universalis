{
  pkgs,
  username,
  ...
}: {
  programs.nh = {
    enable = true;
    clean = {
      enable = false;
      extraArgs = "--keep-since 7d --keep 5";
    };
    flake = "/home/${username}/WS/concepts/Nix-Universalis";
  };

  home.packages = with pkgs; [
    alejandra
    nh
    nix-output-monitor
    nix-prefetch-git
    nvd

    nixd
    nixfmt
    nixpkgs-fmt
  ];
}
