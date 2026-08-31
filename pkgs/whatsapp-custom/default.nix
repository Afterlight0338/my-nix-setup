{ pkgs, lib, ... }:

let
  whatsapp-custom = pkgs.writeShellApplication {
    name = "whatsapp";
    runtimeInputs = [ pkgs.electron ];
    text = ''
      CONFIG_DIR="$HOME/.config/whatsapp-custom"
      
      FLAGS=()
      if [ -n "''${WAYLAND_DISPLAY:-}" ]; then
        FLAGS+=(
          "--enable-features=UseOzonePlatform,WaylandWindowDecorations"
          "--ozone-platform=wayland"
        )
      fi

      exec electron "''${FLAGS[@]}" "$CONFIG_DIR" "$@"
    '';
  };

  whatsapp-desktop-item = pkgs.makeDesktopItem {
    name = "whatsapp-custom";
    desktopName = "WhatsApp";
    comment = "Customizable WhatsApp Desktop Client";
    exec = "whatsapp %U";
    icon = "whatsapp";
    terminal = false;
    type = "Application";
    categories = [ "Network" "InstantMessaging" "Chat" ];
    startupWMClass = "whatsapp-custom";
  };
in
pkgs.symlinkJoin {
  name = "whatsapp-custom";
  paths = [
    whatsapp-custom
    whatsapp-desktop-item
  ];
}
