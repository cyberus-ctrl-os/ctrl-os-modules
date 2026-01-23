{ lib, ... }:

let
  inherit (import ../../../lib { inherit lib; })
    getVendorsModules
    ;
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

  imports = deviceDirs;
}
