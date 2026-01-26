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
            hardware =
              # XXX Installer packages, TBD
              (import ./hardware { inherit pkgs self; })
              # XXX Actual packages, structure TBD too
              // (pkgs.callPackage ./hardware/packages.nix { });
          };
          packages = import ./default.nix { inherit pkgs; };
        };
    }
