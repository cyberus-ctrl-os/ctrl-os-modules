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
        config = lib.mkIf (platform == device) moduleAttrsWithConfig.config;
      }
    ) deviceModules
  );

}
