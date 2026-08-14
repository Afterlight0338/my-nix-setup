{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # yay-managed packages below — do not edit spacing
    unzip
    protonplus
    qbittorrent
    scrcpy
    vlc
    gparted
    easyeffects
    flatpak
    steam
    r2modman
    wl-gammactl
    hyprsunset
    ntfs3g
    steam
    tty-clock
    lavat
    cavalier
    btop
    appimage-run
    ripgrep
  ];
}
