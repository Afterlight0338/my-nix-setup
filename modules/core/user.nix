{ config, pkgs, lib, ... }:

let
  cfg = config.custom.user;
in
{
  options.custom.user = {
    name = lib.mkOption {
      type = lib.types.str;
      default = "afterlight";
      description = "Primary user account name";
    };

    description = lib.mkOption {
      type = lib.types.str;
      default = "Afterlight";
      description = "Primary user display name / description";
    };

    extraGroups = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "networkmanager"
        "wheel"
        "video"
        "audio"
        "input"
      ];
      description = "User group memberships";
    };

    shell = lib.mkOption {
      type = lib.types.package;
      default = pkgs.zsh;
      description = "User default login shell";
    };
  };

  config = {
    users.users.${cfg.name} = {
      isNormalUser = true;
      description = cfg.description;
      extraGroups = cfg.extraGroups;
      shell = cfg.shell;
    };
  };
}
