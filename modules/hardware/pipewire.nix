{ config, lib, ... }:

let
  cfg = config.custom.hardware.audio;
in
{
  options.custom.hardware.audio = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable PipeWire audio server and ALSA/PulseAudio emulation";
    };
  };

  config = lib.mkIf cfg.enable {
    services.pulseaudio.enable = false;
    services.pipewire = {
      enable = true;
      audio.enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };
  };
}
