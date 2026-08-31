{ config, pkgs, lib, ... }:

let
  cfg = config.custom.hardware.intelGpu;
in
{
  options.custom.hardware.intelGpu = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Intel GPU hardware acceleration";
    };
  };

  config = lib.mkIf cfg.enable {
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        intel-media-driver
        intel-vaapi-driver
      ];
    };
  };
}
