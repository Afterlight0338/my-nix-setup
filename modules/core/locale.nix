{ config, lib, ... }:

let
  cfg = config.custom.locale;
in
{
  options.custom.locale = {
    timeZone = lib.mkOption {
      type = lib.types.str;
      default = "Asia/Kuala_Lumpur";
      description = "System timezone";
    };

    defaultLocale = lib.mkOption {
      type = lib.types.str;
      default = "en_US.UTF-8";
      description = "Default system locale";
    };

    extraLocale = lib.mkOption {
      type = lib.types.str;
      default = "en_SG.UTF-8";
      description = "Secondary / format locale";
    };
  };

  config = {
    time.timeZone = cfg.timeZone;
    i18n.defaultLocale = cfg.defaultLocale;

    i18n.extraLocaleSettings = {
      LC_ADDRESS = cfg.extraLocale;
      LC_IDENTIFICATION = cfg.extraLocale;
      LC_MEASUREMENT = cfg.extraLocale;
      LC_MONETARY = cfg.extraLocale;
      LC_NAME = cfg.extraLocale;
      LC_NUMERIC = cfg.extraLocale;
      LC_PAPER = cfg.extraLocale;
      LC_TELEPHONE = cfg.extraLocale;
      LC_TIME = cfg.extraLocale;
    };
  };
}
