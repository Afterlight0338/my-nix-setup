{
  description = "NixOS setup and Roxy Hyprland rice";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Not following our nixpkgs on purpose: the prebuilt kernels in its cache are built
    # against its own pinned nixpkgs, so following ours would compile the kernel locally.
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

    # Same idea: its own nixpkgs keeps quickshell and the shell identical to upstream builds.
    caelestia-cli.url = "github:caelestia-dots/cli";

    linuwu-sense-src = {
      url = "github:0x7375646F/Linuwu-Sense";
      flake = false;
    };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      overlay = import ./pkgs { inherit inputs; };
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ overlay ];
      };

      # Every folder in hosts/ with a default.nix becomes nixosConfigurations.<folder>
      mkHost =
        name:
        nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            { nixpkgs.overlays = [ overlay ]; }
            ./modules
            ./hosts/${name}
          ];
        };
      hosts = builtins.filter (name: builtins.pathExists ./hosts/${name}/default.nix) (
        builtins.attrNames (builtins.readDir ./hosts)
      );
    in
    {
      nixosConfigurations = nixpkgs.lib.genAttrs hosts mkHost;

      packages.${system} = {
        inherit (pkgs) linuwu-sense damx-daemon damx-gui damx-suite;
        setup = pkgs.writeShellScriptBin "setup" ''exec ${./setup} "$@"'';
      };

      # nix run github:Afterlight0338/my-nix-setup
      apps.${system}.default = {
        type = "app";
        program = "${self.packages.${system}.setup}/bin/setup";
        meta.description = "Set this flake up on the current machine";
      };

      formatter.${system} = pkgs.nixfmt;
    };
}
