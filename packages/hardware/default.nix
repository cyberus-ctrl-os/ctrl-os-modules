{ self, pkgs }:

let
  inherit (pkgs) lib;
  inherit (pkgs.stdenv.hostPlatform) system;

  # Evaluate a NixOS configuration without relying on the Flakes entrypoint.
  evalConfig =
    {
      system ? null,
      ...
    }@config:
    (import (pkgs.path + "/nixos/lib/eval-config.nix")) (
      config
      // {
        inherit system;
      }
    );

  # Borrow an arbitrary NixOS eval for evaluating the final `options` with
  # our `hardware` module imported.
  inherit
    (evalConfig {
      modules = [ self.nixosModules.hardware ];
      # The system does not matter, we only need to evaluate up to the options.
      inherit (pkgs.stdenv.hostPlatform) system;
    })
    options
    ;

  devices =
    # Get the device profile option
    options.ctrl-os.hardware.device
    # Unwrap the nullOr
    .type.functor.payload
    # Dig into the `enum`
    .elemType.functor.payload
    # And get the values
    .values;

  # Evaluate the CTRL-OS device modules for the given `device`.
  # This returns the output from the `output` attribute path, with the evaluation
  # merged into the attribute set.
  # By default, `system.build.toplevel` is returned, which is the "system build".
  evaluate =
    device:
    {
      modules ? [ ],
      config ? { },
      output ? [
        "system"
        "build"
        "toplevel"
      ],
    }:

    let
      eval = evalConfig {
        modules = modules ++ [
          (
            { config, ... }:
            {
              imports = [
                self.nixosModules.hardware
                self.nixosModules.profiles
              ];

              # Enable the device-specific config.
              ctrl-os.hardware.device = device;
              ctrl-os.profiles.ctrl-os-system.enable = true;

              # Ensure this system build will use cross-compilation if relevant...
              nixpkgs.buildPlatform = system;
              # ... and tag the system build as such.
              system.nixos.tags = [
                (
                  if config.nixpkgs.hostPlatform.system == config.nixpkgs.buildPlatform.system then
                    "native"
                  else
                    "cross-from-${config.nixpkgs.buildPlatform.system}"
                )
              ];
            }
          )
          config
        ];
      };
    in
    (lib.getAttrFromPath output eval.config) // { inherit eval; };

  # For a given `device`, evaluate the installer config from `path`,
  # relative to the nixpkgs `nixos/modules/installer` path.
  # The output is the (guessed) relevant build output.
  # As with `evaluate`, the system config is added to the derivation
  # attribute set as the `eval` attribute.
  evaluateInstaller =
    device: path:
    let
      installer = evaluate device {
        config =
          { modulesPath, ... }:
          {
            imports = [
              "${modulesPath}/installer/${path}"
            ];

            # This is only safe to do when generating images!!!
            # `stateVersion` should not otherwise be set by an imported modules in a user's config.
            system.stateVersion = pkgs.lib.trivial.release;

            # Make the installer generate the necessary configuration bits.
            # FIXME: this is incomplete right now as the whole installer tooling doesn't know about
            # adding CTRL-OS modules, and has no way to do that in any generic fashion.
            system.nixos-generate-config.desktopConfiguration =
              let
                # Escape string values using JSON, as they are mostly compatible with Nix strings.
                e = builtins.toJSON;
              in
              [
                ''
                  #
                  # WARNING: Using `nixos-generate-config` with CTRL-OS hardware modules is experimental.
                  #
                  # This generated configuration DOES NOT yet include the CTRL-OS configuration for the platform.
                  # You will first need to handle importing the CTRL-OS modules in your configuration.
                  #
                  /*
                  imports = [
                    ctrl-os.nixosModules.hardware
                    ctrl-os.nixosModules.profiles
                  ];

                  ctrl-os.hardware.device = ${e device};
                  ctrl-os.profiles.ctrl-os-system.enable = true;

                  */
                ''
              ];
          };
      };
      inherit (installer.eval.config.system) build;
    in
    (build.isoImage or build.sdImage
      or (builtins.throw "Unable to guess the artifact type for installer path ${builtins.toJSON path}")
    )
    // {
      inherit (installer) eval;
    };
in
{
  devices.installers = lib.listToAttrs (
    lib.map (
      device:
      let
        mkInstaller = evaluateInstaller device;
      in
      {
        name = device;
        value = {
          iso = mkInstaller "cd-dvd/installation-cd-minimal.nix";
          sd-image-new-kernel = mkInstaller "sd-card/sd-image-aarch64-new-kernel-no-zfs-installer.nix";
        };
      }
    ) devices
  );
}
