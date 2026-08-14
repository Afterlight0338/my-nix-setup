{ pkgs, ... }:

{
  # Storage discovery and mounting backend.
  services.udisks2.enable = true;

  # Trash, network locations, phones and related desktop integration.
  services.gvfs.enable = true;

  environment.systemPackages = with pkgs; [
    udiskie
  ];
}
