{
  stdenv,
  lib,
  kmod,
  linuxPackages,
  src,
}:

stdenv.mkDerivation {
  pname = "linuwu-sense";
  version = "unstable";

  inherit src;

  nativeBuildInputs = [
    kmod
    linuxPackages.kernel.dev
  ];

  # Workaround strncpy -> strscpy for newer kernels
  postPatch = ''
    sed -i 's/strncpy/strscpy/g' src/linuwu_sense.c 2>/dev/null || true
  '';

  buildPhase = ''
    runHook preBuild

    make -C ${linuxPackages.kernel.dev}/lib/modules/${linuxPackages.kernel.modDirVersion}/build \
      M=$(pwd) \
      modules

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/modules/${linuxPackages.kernel.modDirVersion}/extra
    cp src/*.ko $out/lib/modules/${linuxPackages.kernel.modDirVersion}/extra/

    runHook postInstall
  '';

  meta = with lib; {
    description = "Kernel drivers for Acer laptop WMI controls";
    homepage = "https://github.com/0x7375646F/Linuwu-Sense";
    license = licenses.gpl2Plus;
    platforms = [ "x86_64-linux" ];
  };
}
