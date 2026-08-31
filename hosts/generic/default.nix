{ lib, ... }:

{
  imports = [
    # Automatically include host-generated hardware configuration if running on target system
    (if builtins.pathExists /etc/nixos/hardware-configuration.nix
     then /etc/nixos/hardware-configuration.nix
     else ./hardware-configuration.nix)
  ];

  networking.hostName = lib.mkDefault "nixos";

  # Standard UEFI Bootloader
  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;

  # Generic user configuration (overridable)
  custom = {
    user.name = lib.mkDefault "nixos";
    user.description = lib.mkDefault "NixOS User";
  };

  system.stateVersion = lib.mkDefault "26.05";
}
