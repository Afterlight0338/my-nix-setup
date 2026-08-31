{ pkgs, lib, ... }:

{
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = lib.mkDefault true;
    trusted-users = [
      "root"
      "@wheel"
    ];
  };

  nixpkgs.config.allowUnfree = lib.mkDefault true;
}
