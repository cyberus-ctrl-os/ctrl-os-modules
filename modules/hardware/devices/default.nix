{ config, lib, ... }:

let
  inherit (import ../../../lib { inherit lib; })
    getVendorsModules
    ;
  cfg = config.ctrl-os.hardware;
  deviceModules = getVendorsModules ./.;
  devices = builtins.attrNames deviceModules;
  deviceDirs = builtins.attrValues deviceModules;
in
{
  options.ctrl-os.hardware.device = lib.mkOption {
    type = with lib.types; nullOr (enum devices);
    description = "Selects a hardware device profile to use by device name.";
    default = null;
  };

  # Expose the `deviceList` for programmatic usage.
  options.ctrl-os.hardware.deviceList = lib.mkOption {
    default = devices;
    readOnly = true;
    internal = true;
  };

  # Create `config.ctrl-os.hardware.devices.${name}.enable` for every device.
  # The option can be used internally as needed.
  options.ctrl-os.hardware.devices = builtins.mapAttrs (name: _: {
    enable = lib.mkEnableOption "device support for the ${name}" // {
      default = cfg.device == name;
      internal = true;
      readOnly = true;
    };
  }) deviceModules;

  imports = deviceDirs;
}
