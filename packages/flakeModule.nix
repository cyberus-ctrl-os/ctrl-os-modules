{
  withSystem,
  inputs,
  self,
  ...
}:
{ }
//
  inputs.nixpkgs.lib.optionalAttrs
    (inputs.nixpkgs.lib.versionAtLeast inputs.nixpkgs.lib.version "25.11")
    {
      flake.overlays = rec {
        default = vms;
        vms =
          _: prev:
          withSystem prev.stdenv.hostPlatform.system (
            { config, ... }:
            {
              scl = config.packages.scl;
              OVMF-cloud-hypervisor = config.packages.OVMF-cloud-hypervisor;
            }
          );
      };

      perSystem =
        { pkgs, ... }:
        {
          legacyPackages = {
            hardware = import ./hardware {
              inherit pkgs self;
            };
          };
          packages = import ./default.nix { inherit pkgs; };
        };
    }
