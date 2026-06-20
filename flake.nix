{
  description = "Nix Universalis: portable Home Manager dev graph";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    home-manager,
    ...
  }: let
    system = "x86_64-linux";
    username = "spaceinvaders";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
    specialArgs = {
      inherit inputs system username;
    };
  in {
    homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = specialArgs;
      modules = [
        ./profiles/home/dev-core.nix
      ];
    };

    formatter.${system} = pkgs.writeShellApplication {
      name = "format-nix-universalis";
      runtimeInputs = [pkgs.alejandra];
      text = ''
        alejandra .
      '';
    };
  };
}
