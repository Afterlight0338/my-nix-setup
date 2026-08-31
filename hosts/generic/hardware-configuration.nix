# Generic template hardware-configuration.nix
# On a fresh installation, replace this file with the output of:
#   nixos-generate-config --show-hardware-config > hosts/<hostname>/hardware-configuration.nix

{ lib, ... }:

{
  # Minimal fallback mounts to ensure successful evaluation out of the box
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
