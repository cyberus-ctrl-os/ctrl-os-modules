{ config, lib, ... }@moduleArgs:

let
  cfg = config.ctrl-os.hardware;
  inherit (import ../../../lib { inherit lib; })
    getVendorsModules
    ;
  deviceModules = getVendorsModules ./.;
  devices = builtins.attrNames deviceModules;
in
{
  options.ctrl-os.hardware.device = lib.mkOption {
    type = with lib.types; nullOr (enum devices);
    description = "Selects a hardware device profile to use by device name.";
    default = null;
  };

  imports = builtins.attrValues (
    builtins.mapAttrs (
      device: dir:
      let
        cfgOrFn = import dir;
        appliedConfig =
          let
            config = cfgOrFn moduleArgs;
          in
          if config ? config then config else { inherit config; };
        cond = lib.mkIf (cfg.device == device);
      in
      if builtins.isAttrs cfgOrFn then
        {
          config = cond (cfgOrFn);
        }
      else
        appliedConfig
        // {
          config = cond appliedConfig.config;
        }
    ) deviceModules
  );
}
