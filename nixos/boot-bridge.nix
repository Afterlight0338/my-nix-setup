{ lib, pkgs, ... }:

{
  # CachyOS GRUB remains the real firmware bootloader.
  boot.loader.grub.enable = lib.mkForce false;

  # NixOS uses this only to maintain kernels, initrds and generations on /boot.
  boot.loader.systemd-boot = {
    enable = lib.mkForce true;
    configurationLimit = lib.mkForce 10;

    extraInstallCommands = lib.mkForce ''
      export PATH=${pkgs.coreutils}/bin:${pkgs.findutils}/bin:${pkgs.gnused}/bin

      ${pkgs.bash}/bin/bash \
        /etc/nixos/generate-grub-direct.sh

      # Keep Acer's fallback loader pointing to signed CachyOS GRUB.
      if [ -f /boot/EFI/cachyos/grubx64.efi ]; then
        ${pkgs.coreutils}/bin/install \
          -Dm0644 \
          /boot/EFI/cachyos/grubx64.efi \
          /boot/EFI/BOOT/BOOTX64.EFI
      fi
    '';
  };

  boot.loader.efi = {
    canTouchEfiVariables = lib.mkForce false;
    efiSysMountPoint = lib.mkForce "/boot";
  };

  boot.loader.timeout = lib.mkForce 10;
}
