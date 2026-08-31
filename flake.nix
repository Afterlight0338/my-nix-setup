{
  description = "Modular, portable & reproducible NixOS flake configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    nix-cachyos-kernel = {
      url = "github:xddxdd/nix-cachyos-kernel/release";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    linuwu-sense-src = {
      url = "github:0x7375646F/Linuwu-Sense";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      nix-cachyos-kernel,
      linuwu-sense-src,
      ...
    }@inputs:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Custom package overlays
      customOverlay = import ./pkgs { inherit inputs; };

      # Helper for building host configurations
      mkHost =
        {
          system ? "x86_64-linux",
          hostname,
          modules ? [ ],
          specialArgs ? { },
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs self;
          } // specialArgs;
          modules = [
            {
              nixpkgs.overlays = [ customOverlay ];
              nixpkgs.config.allowUnfree = true;
            }
            ./modules
            ./hosts/${hostname}
          ] ++ modules;
        };
    in
    {
      nixosConfigurations = {
        # Host: Acer Nitro V 15 (Afterlight's daily driver)
        nixos = mkHost {
          hostname = "nixos";
        };

        # Alias for Nitro V 15
        nitro-v15 = mkHost {
          hostname = "nixos";
        };

        # Portable generic template host (for new machines & fresh installs)
        generic = mkHost {
          hostname = "generic";
        };

        # Default fallback
        default = mkHost {
          hostname = "generic";
        };
      };

      # Exported packages for standalone usage
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = [ customOverlay ];
          };
        in
        {
          linuwu-sense = pkgs.linuwu-sense;
          damx-daemon = pkgs.damx-daemon;
          damx-gui = pkgs.damx-gui;
          damx-suite = pkgs.damx-suite;
          whatsapp-custom = pkgs.whatsapp-custom;
        }
      );

      # Reusable NixOS modules exported for external consumption
      nixosModules = {
        default = ./modules;
        core = ./modules/core;
        desktop = ./modules/desktop;
        hardware = ./modules/hardware;
        gaming = ./modules/gaming;
        apps = ./modules/apps;
        system = ./modules/system;
      };

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);
    };
}
