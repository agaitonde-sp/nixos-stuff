{

  description = "Random nix stuff. Nixos+home-manager+neovim";

  nixConfig = {
    extra-substituters = " https://nix-community.cachix.org https://adgai19.cachix.org https://hyprland.cachix.org";
    extra-trusted-public-keys = " nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= adgai19.cachix.org-1:AkyyWarR6y2bfy3YPYLrKjjoLlzUvyKNhvflZ+eW3tk= hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=";
    extra-experimental-features = "nix-command flakes";
  };

  inputs = {
    neovim-nightly = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.url = "github:nixos/nixpkgs?rev=fad51abd42ca17a60fc1d4cb9382e2d79ae31836";
    };

    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    nixpkgs-stable = { url = "github:nixos/nixpkgs/nixos-22.11"; };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    firefox-overlay = {
      url = "github:mozilla/nixpkgs-mozilla";
    };

    tokyonight-tmux = {
      url = "github:janoamaral/tokyo-night-tmux";
      flake = false;
    };

    base16-tmux = {
      url = "github:tinted-theming/base16-tmux";
      flake = false;
    };

    hyprland.url = "github:hyprwm/Hyprland";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # some plugins that I track outside of nixpkgs and vim-extra-plugins
    inc-rename = {
      url = "github:smjonas/inc-rename.nvim";
      flake = false;
    };

    vim-just = {
      url = "github:NoahTheDuke/vim-just";
      flake = false;
    };

    treesitter-just = {
      url = "github:IndianBoy42/tree-sitter-just";
      flake = false;
    };
    regexplainer = {
      url = "github:bennypowers/nvim-regexplainer";
      flake = false;
    };

    go-nvim = {
      url = "github:ray-x/go.nvim";
      flake = false;
    };

    guihua-nvim = {
      url = "github:ray-x/guihua.lua";
      flake = false;
    };

    drop-nvim = {
      url = "github:folke/drop.nvim";
      flake = false;
    };

    astro-vim = {
      url = "github:wuelnerdotexe/vim-astro";
      flake = false;
    };

    cyclist-nvim = {
      url = "github:tjdevries/cyclist.vim";
      flake = false;
    };

    autosave-nvim = {
      url = "github:Pocco81/auto-save.nvim";
      flake = false;
    };

    typescript-nvim = {
      url = "github:jose-elias-alvarez/typescript.nvim";
      flake = false;
    };

    lspcontainers-nvim = {
      url = "github:lspcontainers/lspcontainers.nvim";
      flake = false;
    };

    noice-nvim = {
      url = "github:folke/noice.nvim";
      flake = false;
    };

    nvim-dap-go = {
      url = "github:leoluz/nvim-dap-go";
      flake = false;
    };

    statuscol-nvim = {
      url = "github:luukvbaal/statuscol.nvim";
      flake = false;
    };

    hover-nvim = {
      url = "github:lewis6991/hover.nvim";
      flake = false;
    };

    jester = {
      url = "github:David-Kunz/jester";
      flake = false;
    };

    neotest-jest = {
      url = "github:haydenmeade/neotest-jest";
      flake = false;
    };
    dap-vscode = {
      url = "github:mxsdev/nvim-dap-vscode-js";
      flake = false;
    };


    # codeium-vim = {
    #   url = "github:Exafunction/codeium.vim";
    #   flake = false;
    # };
  };
  outputs = inputs@{ nixpkgs, nixpkgs-stable, home-manager, neovim-nightly, sops-nix, hyprland, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
      };

      overlays = [
        inputs.neovim-nightly.overlay
        inputs.poetry2nix.overlay
        inputs.firefox-overlay.overlay
        (import ./users/common/overlays.nix inputs)
      ];

    in
    {

      devShells."${system}".default = pkgs.mkShellNoCC {
        packages = with pkgs;[ git zsh nixpkgs-fmt just ];
        shellHook = ''echo Inside nix dev shell'';
      };

      packages."${system}" = import ./packages inputs;

      overlays.default = final: prev: (import ./users/common/overlays.nix inputs) final prev;

      homeConfigurations = {
        ubuntu-vm = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./hosts/ubunbu-vm/home.nix ];
        };
      };

      nixosConfigurations = {
        legion = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./system/legion/configuration.nix
            sops-nix.nixosModules.sops
            hyprland.nixosModules.default
            {

              programs.hyprland = {
                enable = true;
                xwayland = {
                  enable = true;
                };

                nvidiaPatches = true;
              };
            }
            home-manager.nixosModules.home-manager
            {

              nixpkgs.overlays = overlays;
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              # the magic keywords LUL
              home-manager.extraSpecialArgs = { inherit system inputs; };
              home-manager.users.adgai = import ./hosts/legion/home.nix;
            }
          ];

        };

        vms = nixpkgs.lib.nixosSystem {
          inherit system;
        };

      };
    };
}
