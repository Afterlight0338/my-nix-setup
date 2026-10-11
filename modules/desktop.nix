{ config, lib, pkgs, inputs, ... }:

# Hyprland + Caelestia shell, the Roxy theme (GTK, Qt, icons, fonts), Dolphin,
# and optionally a boot splash and autologin.
let
  cfg = config.custom.desktop;
  system = pkgs.stdenv.hostPlatform.system;

  # Plymouth's stock spinner theme with Roxy's snowflake on the Caelestia background
  roxySplash = pkgs.runCommand "plymouth-theme-roxy" { } ''
    src=${pkgs.plymouth}/share/plymouth/themes/spinner
    dir=$out/share/plymouth/themes/roxy
    mkdir -p $dir
    cp $src/*.png $dir/
    cp ${./assets/roxy-splash.png} $dir/watermark.png
    sed -e "s|^ImageDir=.*|ImageDir=$dir|" \
        -e '/^Name\[/d' -e 's|^Name=.*|Name=Roxy|' \
        -e 's|^WatermarkVerticalAlignment=.*|WatermarkVerticalAlignment=.42|' \
        -e 's|^VerticalAlignment=.*|VerticalAlignment=.72|' \
        -e 's|^BackgroundStartColor=.*|BackgroundStartColor=0x171a24|' \
        -e 's|^BackgroundEndColor=.*|BackgroundEndColor=0x171a24|' \
        $src/spinner.plymouth > $dir/roxy.plymouth
  '';

  session = "uwsm start hyprland-uwsm.desktop";
in
{
  options.custom.desktop = {
    hyprland.enable = lib.mkEnableOption "Hyprland" // { default = true; };
    theme.enable = lib.mkEnableOption "the Roxy theme and Caelestia shell" // { default = true; };
    fileManager.enable = lib.mkEnableOption "Dolphin and Thunar" // { default = true; };
    splash.enable = lib.mkEnableOption "the Roxy boot splash and a quiet boot";
    # Boots straight into Hyprland; the session locks itself (hypr-user.lua), and if Hyprland
    # exits you get a normal tuigreet login
    autologin.enable = lib.mkEnableOption "logging in automatically";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.hyprland.enable {
      programs.hyprland = {
        enable = true;
        xwayland.enable = true;
        withUWSM = true;
      };
      environment.sessionVariables.NIXOS_OZONE_WL = "1"; # Electron apps on Wayland
      services.xserver.xkb.layout = lib.mkDefault "us";

      environment.systemPackages = with pkgs; [
        kitty firefox
        wl-clipboard grim slurp brightnessctl pavucontrol networkmanagerapplet nwg-displays
        hyprsunset wl-gammactl # night light and gamma (Settings page)
      ];
    })

    (lib.mkIf cfg.theme.enable {
      programs.dconf.enable = true;
      fonts.packages = with pkgs; [
        nerd-fonts.jetbrains-mono noto-fonts noto-fonts-cjk-sans noto-fonts-color-emoji
      ];
      environment.systemPackages = with pkgs; [
        glib.bin dconf gsettings-desktop-schemas
        adw-gtk3 papirus-icon-theme
        darkly # Qt style picked in ~/.config/qtengine, glass via ~/.config/darklyrc
        fastfetch btop jq bat ripgrep lazygit trash-cli hyprpicker cliphist
        inputs.caelestia-cli.packages.${system}.with-shell
      ];

      # Brave's toolbar in the Roxy surface colour. Brave then says "Managed by your
      # organization" in its menu; that's only this policy.
      environment.etc."brave/policies/managed/caelestia.json".text = builtins.toJSON {
        BrowserThemeColor = "#232735";
        BrowserColorScheme = "device";
      };
    })

    (lib.mkIf cfg.fileManager.enable {
      services.udisks2.enable = true;
      services.gvfs.enable = true; # trash, phones (MTP), network places
      services.tumbler.enable = true; # thumbnails
      programs.dconf.enable = true;
      environment.systemPackages = with pkgs; [
        kdePackages.dolphin kdePackages.kio kdePackages.kio-extras kdePackages.kio-fuse
        kdePackages.kio-admin kdePackages.ffmpegthumbs kdePackages.ark kdePackages.kservice
        kdePackages.kde-cli-tools kdePackages.qtsvg kdePackages.breeze
        qtengine shared-mime-info p7zip unrar gnome-themes-extra thunar udiskie
      ];
    })

    (lib.mkIf cfg.splash.enable {
      boot.plymouth = {
        enable = true;
        theme = "roxy";
        themePackages = [ roxySplash ];
      };
      # Log text stays out of the way of the splash (still in journalctl -b)
      boot.consoleLogLevel = 3;
      boot.initrd.verbose = false;
      boot.kernelParams = [ "quiet" "splash" "udev.log_level=3" "systemd.show_status=auto" ];
    })

    (lib.mkIf cfg.autologin.enable {
      services.greetd = {
        enable = true;
        settings = {
          initial_session = {
            command = session;
            user = config.custom.user.name;
          };
          default_session = {
            command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd '${session}'";
            user = "greeter";
          };
        };
      };
    })
  ];
}
