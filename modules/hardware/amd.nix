{ config, pkgs, lib, ... }:

let
  cfg = config.custom.hardware.amdGpu;
in
{
  options.custom.hardware.amdGpu = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable AMD GPU graphics drivers and Vulkan support";
    };
  };

  config = lib.mkIf cfg.enable {
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    services.xserver.videoDrivers = [ "amdgpu" ];
  };
}
