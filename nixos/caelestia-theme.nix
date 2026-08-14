{ pkgs, ... }:

let
  roxyPalette = import ./roxy-palette.nix;

  adwTheme =
    if builtins.hasAttr "adw-gtk3" pkgs
    then builtins.getAttr "adw-gtk3" pkgs
    else builtins.getAttr "adw-gtk-theme" pkgs;

  jetbrainsNerd =
    if builtins.hasAttr "nerd-fonts" pkgs
    then pkgs.nerd-fonts.jetbrains-mono
    else builtins.getAttr "nerd-fonts-jetbrains-mono" pkgs;
in
{
  # Central Roxy Migurdia Palette injection for desktop theme modules
  _module.args.roxyPalette = roxyPalette;

  programs.dconf.enable = true;

  fonts.packages = [
    jetbrainsNerd
    pkgs.noto-fonts
    pkgs.noto-fonts-cjk-sans
    pkgs.noto-fonts-color-emoji
  ];

  environment.systemPackages = [
    # GTK settings tools and schemas
    pkgs.glib.bin
    pkgs.dconf
    pkgs.gsettings-desktop-schemas

    adwTheme
    pkgs.papirus-icon-theme

    pkgs.fastfetch
    pkgs.btop
    pkgs.jq
    pkgs.bat
    pkgs.ripgrep
    pkgs.lazygit
    pkgs.trash-cli
    pkgs.hyprpicker
    pkgs.cliphist
  ];
}
