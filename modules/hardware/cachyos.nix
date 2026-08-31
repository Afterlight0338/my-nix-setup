{ config, pkgs, lib, inputs, ... }:

let
  cfg = config.custom.hardware.cachyosKernel;
in
{
  options.custom.hardware.cachyosKernel = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable CachyOS optimized kernel with BORE scheduler and binary cache";
    };

    package = lib.mkOption {
      type = lib.types.raw;
      default = pkgs.cachyosKernels.linuxPackages-cachyos-bore-x86_64-v3;
      description = "CachyOS kernel package to use";
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = lib.mkIf (inputs ? nix-cachyos-kernel) [
      inputs.nix-cachyos-kernel.overlays.pinned
    ];

    boot.kernelPackages = cfg.package;

    nix.settings = {
      substituters = [
        "https://attic.xuyh0120.win/lantian"
      ];
      trusted-public-keys = [
        "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
      ];
    };
  };
}
