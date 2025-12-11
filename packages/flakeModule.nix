{ withSystem, ... }:
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
      packages = import ./default.nix { inherit pkgs; };
    };
}
