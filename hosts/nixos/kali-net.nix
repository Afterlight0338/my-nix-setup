# Kali VM network: br-kali (10.77.0.0/24) NATed out of wlp4s0.
# Wi-Fi can't be L2-bridged, so the VM is routed: it reaches the LAN at L3
# (nmap -sS/-sU, ICMP work) and LAN hosts reach it via the forwarded ports.
{ pkgs, ... }:

{
  networking.bridges.br-kali.interfaces = [ ];
  networking.interfaces.br-kali.ipv4.addresses = [
    { address = "10.77.0.1"; prefixLength = 24; }
  ];
  networking.networkmanager.unmanaged = [ "br-kali" ];
  networking.firewall.trustedInterfaces = [ "br-kali" ];

  networking.nat = {
    enable = true;
    internalInterfaces = [ "br-kali" ];
    externalInterface = "wlp4s0";
    # LAN -> host:port -> Kali (ssh, listeners/reverse shells, http server)
    forwardPorts = [
      { sourcePort = 2222; destination = "10.77.0.10:22"; proto = "tcp"; }
      { sourcePort = 4444; destination = "10.77.0.10:4444"; proto = "tcp"; }
      { sourcePort = 8000; destination = "10.77.0.10:8000"; proto = "tcp"; }
    ];
  };
  networking.firewall.allowedTCPPorts = [ 2222 4444 8000 ];

  # DHCP only (port=0 disables DNS), pins the VM's MAC to 10.77.0.10.
  services.dnsmasq = {
    enable = true;
    resolveLocalQueries = false;
    settings = {
      port = 0;
      interface = "br-kali";
      bind-dynamic = true;
      dhcp-range = "10.77.0.50,10.77.0.150,12h";
      dhcp-host = "52:54:00:4b:41:10,10.77.0.10";
      dhcp-option = [ "3,10.77.0.1" "6,1.1.1.1,8.8.8.8" ];
    };
  };

  # Lets unprivileged qemu attach a tap to br-kali.
  environment.etc."qemu/bridge.conf".text = "allow br-kali\n";
  security.wrappers.qemu-bridge-helper = {
    source = "${pkgs.qemu}/libexec/qemu-bridge-helper";
    owner = "root";
    group = "root";
    setuid = true;
  };
}
