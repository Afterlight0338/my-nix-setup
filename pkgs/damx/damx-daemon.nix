{
  stdenv,
  lib,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  zlib,
}:

let
  version = "0.9.1";
  sha256 = "sha256-2amtWkZh+ASPmN6p6alWo8shnrpy7AdhRGlAdc7WlIQ=";
in
stdenv.mkDerivation {
  pname = "damx-daemon";
  inherit version;

  src = fetchurl {
    url = "https://github.com/PXDiv/Div-Acer-Manager-Max/releases/download/v${version}/DAMX-${version}.tar.xz";
    inherit sha256;
  };

  setSourceRoot = ''
    sourceRoot=$(echo */DAMX-Daemon)
  '';

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    zlib
  ];

  dontBuild = true;

  installPhase = ''
    mkdir -p $out/bin
    cp DAMX-Daemon $out/bin/damx-daemon
    chmod +x $out/bin/damx-daemon
  '';

  meta = with lib; {
    description = "Daemon service for DAMX Suite";
    homepage = "https://github.com/PXDiv/Div-Acer-Manager-Max";
    platforms = [ "x86_64-linux" ];
  };
}
