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
        # The module may be an attribute set, or a function.
        module = import dir;

        # Get an attribute set from the module
        moduleAttrs = if builtins.isAttrs module then module else module moduleArgs;

        # Since we are adding an `mkIf` for the module file,
        # we need to apply it to the whole `config` value...
        # ... which may be implicit in a module, so get a `config` in that case.
        moduleAttrsWithConfig = if moduleAttrs ? config then moduleAttrs else { config = moduleAttrs; };
      in
      # Finally, insert the `mkIf` in the module.
      moduleAttrsWithConfig
      // {
        config = lib.mkIf (cfg.device == device) moduleAttrsWithConfig.config;
      }
    ) deviceModules
  );
}
