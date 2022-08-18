{
  description = "My nix config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-22.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { nixpkgs, home-manager, ... }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config = { allowUnfree = true; };
      lib = nixpkgs.lib;
    };

  in {
    homeManagerConfigurations = {
      adgai = home-manager.lib.homeManagerConfiguration {
        inherit system pkgs;
	username = "adgai";
	homeDirectory = "/home/adgai";
	stateVersion = "22.05";
	configuration = {
	  imports = [./users/adgai/home.nix];
	};
      };
    };
    nixosConfigurations = {
      adgai = nixpkgs.lib.nixosSystem {
        inherit system;
	modules = [./system/configuration.nix];
      };
    };
  };
}
