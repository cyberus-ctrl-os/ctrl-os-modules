{ config, lib, ... }:

let
  cfg = config.ctrl-os.profiles.developer;

  # Makes an "enable" option that defaults to the `developer.enable` state.
  mkDefaultEnable =
    description:
    (lib.mkEnableOption description)
    // {
      default = cfg.enable;
      defaultText = "config.ctrl-os.profiles.developer.enable";
    };
in
{
  options = {
    ctrl-os.profiles.developer = {
      enable = lib.mkEnableOption "the opinionated CTRL-OS developer settings";
      useFlakes = mkDefaultEnable "system-wide usage of Flakes";
      useCache = mkDefaultEnable "system-wide usage of the CTRL-OS binary cache";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.useCache {
      ctrl-os.profiles.ctrl-os-system.useCache = true;
    })
    (lib.mkIf cfg.useFlakes {
      ctrl-os.profiles.ctrl-os-system.useFlakes = true;
    })
  ];
}
