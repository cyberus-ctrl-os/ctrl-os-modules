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
  options.ctrl-os.platform = lib.mkOption {
    type = with lib.types; nullOr (enum devices);
    description = "The platform, we are running on.";
    default = null;
  };

  imports = deviceDirs;
}
