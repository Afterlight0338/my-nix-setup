{ pkgs, lib, ... }:

{
  programs.zsh = {
    enable = lib.mkDefault true;
    ohMyZsh = {
      enable = lib.mkDefault true;
      theme = "";
      plugins = [ "git" ];
    };
  };

  environment.systemPackages = with pkgs; [
    fastfetch
  ];
}
