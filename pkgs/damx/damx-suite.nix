{
  symlinkJoin,
  damx-daemon,
  damx-gui,
}:

symlinkJoin {
  name = "damx-suite";
  paths = [
    damx-daemon
    damx-gui
  ];
}
