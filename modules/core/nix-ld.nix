{ config, pkgs, lib, ... }:

let
  cfg = config.custom.core.nixLd;
in
{
  options.custom.core.nixLd = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable nix-ld dynamic linker for unpatched ELF binaries";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.nix-ld = {
      enable = true;
      libraries = with pkgs; [
        stdenv.cc.cc
        zlib
        glib
        icu
        openssl
        libxml2
        fuse3
        libsecret
        dbus
        cups
        libusb1
        nspr
        nss
        fontconfig
        freetype
        pango
        cairo
        atk
        gdk-pixbuf

        # Displays (X11 / Wayland / OpenGL / Vulkan)
        libx11
        libxcursor
        libxinerama
        libxext
        libxrandr
        libxi
        libxfixes
        libxrender
        libxcb
        libxcomposite
        libxdamage
        libxshmfence
        libxkbcommon
        wayland
        libGL
        vulkan-loader

        # Audio
        alsa-lib
        libpulseaudio
      ];
    };
  };
}
