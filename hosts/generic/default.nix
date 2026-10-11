{ lib, ... }:

# Fallback for `nixos-rebuild --flake .#generic` on any machine: uses that machine's own
# hardware scan when there is one. The setup wizard writes a proper host instead.
{
  imports = [
    (if builtins.pathExists /etc/nixos/hardware-configuration.nix
     then /etc/nixos/hardware-configuration.nix
     else ./hardware-configuration.nix)
  ];

  networking.hostName = lib.mkDefault "nixos";
  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;

  system.stateVersion = lib.mkDefault "26.05";
}
