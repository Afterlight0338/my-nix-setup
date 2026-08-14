{ pkgs, ... }:

{
  programs.zsh = {
    enable = true;

    ohMyZsh = {
      enable = true;
      theme = "";
      plugins = [ "git" ];
    };
  };

  users.users.afterlight.shell = pkgs.zsh;

  environment.systemPackages = with pkgs; [
    fastfetch
  ];
}
