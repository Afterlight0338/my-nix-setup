{
  pkgs,
  stdenv,
  lib,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  gtk3,
  glib,
  libglvnd,
  fontconfig,
  freetype,
  zlib,
  libdrm,
  mesa,
  openssl,
  icu,
  krb5,
  harfbuzz,
  expat,
}:

let
  version = "0.9.1";
  sha256 = "sha256-2amtWkZh+ASPmN6p6alWo8shnrpy7AdhRGlAdc7WlIQ=";

  runtimeLibs = [
    stdenv.cc.cc.lib
    gtk3
    glib
    pkgs.libx11
    pkgs.libxext
    pkgs.libxrender
    pkgs.libxi
    pkgs.libxcursor
    pkgs.libxrandr
    pkgs.libxinerama
    pkgs.libxfixes
    pkgs.libxdamage
    pkgs.libxcb
    pkgs.libice
    pkgs.libsm
    libglvnd
    fontconfig
    freetype
    harfbuzz
    zlib
    libdrm
    mesa
    openssl
    icu
    krb5
    expat
  ];
in

stdenv.mkDerivation rec {
  pname = "damx-gui";
  inherit version;

  src = fetchurl {
    url = "https://github.com/PXDiv/Div-Acer-Manager-Max/releases/download/v${version}/DAMX-${version}.tar.xz";
    inherit sha256;
  };

  setSourceRoot = ''
    sourceRoot=$(echo */DAMX-GUI)
  '';

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = runtimeLibs;
  dontBuild = true;

  installPhase =
    let
      desktopEntry = pkgs.makeDesktopItem {
        name = "${pname}";
        desktopName = "DAMX";
        exec = "${pname}";
        icon = "damx";
        comment = "Div Acer Manager Max";
        categories = [
          "Utility"
          "System"
        ];
      };
    in
    ''
      mkdir -p $out/bin $out/share/damx $out/share/icons/hicolor/256x256/apps $out/share/applications

      cp -r * $out/share/damx/
      chmod +x $out/share/damx/DivAcerManagerMax

      if [ -f $out/share/damx/libSkiaSharp.so ]; then
        chmod +x $out/share/damx/libSkiaSharp.so
      fi

      cp icon.png $out/share/icons/hicolor/256x256/apps/damx.png 2>/dev/null || true
      cp icon.png $out/share/icons/hicolor/256x256/apps/DAMX.png 2>/dev/null || true

      cp ${desktopEntry}/share/applications/${pname}.desktop $out/share/applications/${pname}.desktop

      makeWrapper $out/share/damx/DivAcerManagerMax $out/bin/damx-gui \
        --chdir $out/share/damx \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeLibs}" \
        --prefix LD_LIBRARY_PATH : "$out/share/damx" \
        --set DOTNET_SYSTEM_GLOBALIZATION_INVARIANT 0 \
        --set AVALONIA_RENDERING_MODE software

      ln -s $out/bin/damx-gui $out/bin/DAMX
    '';

  meta = with lib; {
    description = "GUI for DAMX Suite";
    homepage = "https://github.com/PXDiv/Div-Acer-Manager-Max";
    platforms = [ "x86_64-linux" ];
  };
}
