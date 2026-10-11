# Generic template hardware-configuration.nix
# On a fresh installation, replace this file with the output of:
#   nixos-generate-config --show-hardware-config > hosts/<hostname>/hardware-configuration.nix

{ lib, ... }:

{
  # Placeholder mounts so the flake evaluates on machines without /etc/nixos
  fileSystems."/" = lib.mkDefault {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = lib.mkDefault {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
