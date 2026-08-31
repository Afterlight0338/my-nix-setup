{ inputs, ... }:

final: prev: {
  linuwu-sense = (final.callPackage ./damx/linuwu-sense.nix {
    src = inputs.linuwu-sense-src;
    linuxPackages = final.linuxPackages;
  });
  damx-daemon = final.callPackage ./damx/damx-daemon.nix { };
  damx-gui = final.callPackage ./damx/damx-gui.nix { };
  damx-suite = final.callPackage ./damx/damx-suite.nix { };
  whatsapp-custom = final.callPackage ./whatsapp-custom { };
}
