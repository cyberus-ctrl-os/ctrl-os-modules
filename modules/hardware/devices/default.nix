{ config, lib, ... }@moduleArgs:

let
  platform = config.ctrl-os.platform;
  inherit
    (import ../../../lib { inherit lib; })
    getVendorsModules
    ;
  deviceModules = getVendorsModules ./.;
  devices = builtins.attrNames deviceModules;
in
{
  options.ctrl-os.platform = lib.mkOption {
    type = with lib.types; nullOr (enum devices);
    description = "The platform, we are running on.";
    default = null;
  };

  imports =
    builtins.attrValues
    (
      builtins.mapAttrs
      (
        device: dir:
        let
          cfgOrFn = import dir;
          appliedConfig =
            let config = cfgOrFn moduleArgs; in
            if config ? config then
              config
            else
              { inherit config; }
          ;
          cond = lib.mkIf (platform == device);
        in
          if builtins.isAttrs cfgOrFn then
            {
              config = cond (
                cfgOrFn
              );
            }
          else
            appliedConfig // {
              config = cond appliedConfig.config;
            }
      )
      deviceModules
    )
  ;
}
