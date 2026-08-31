{ pkgs, lib, ... }:

{
  security.polkit.enable = lib.mkDefault true;
  security.rtkit.enable = lib.mkDefault true;

  # Polkit authentication agent daemon (systemd user service)
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome-authentication-agent-1";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  # Secret service / Keyring for saving passwords (browsers, Discord, Git, VSCode)
  services.gnome.gnome-keyring.enable = lib.mkDefault true;
  security.pam.services.hyprland.enableGnomeKeyring = lib.mkDefault true;

  environment.systemPackages = with pkgs; [
    polkit_gnome
  ];
}
