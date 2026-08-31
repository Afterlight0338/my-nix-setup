{ config, pkgs, lib, ... }:

let
  cfg = config.custom.desktop.hyprland;
in
{
  options.custom.desktop.hyprland = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Hyprland Wayland compositor";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
      withUWSM = true;
    };

    environment.sessionVariables = {
      # Force Electron / Chromium apps to run natively on Wayland
      NIXOS_OZONE_WL = "1";
    };

    # Input keyboard layout
    services.xserver.xkb = {
      layout = lib.mkDefault "us";
      variant = lib.mkDefault "";
    };

    environment.systemPackages = with pkgs; [
      kitty
      firefox
      wl-clipboard
      grim
      slurp
      brightnessctl
      pavucontrol
      networkmanagerapplet
      nwg-displays
    ];
  };
}
