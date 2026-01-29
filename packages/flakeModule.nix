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
        { pkgs, system, ... }:
        {
          packages = (import ./default.nix { inherit pkgs; }) // {
            jetsonOrinNanoInstaller =
              (inputs.nixpkgs.lib.nixosSystem {
                modules = [
                  (
                    { modulesPath, ... }:
                    {
                      imports = [
                        "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
                        self.nixosModules.hardware
                        self.nixosModules.profiles
                      ];

                      ctrl-os.profiles.developer.enable = true;
                      ctrl-os.hardware.device = "nvidia-jetson-orin-nano-super";
                      nixpkgs.hostPlatform = "aarch64-linux";
                      nixpkgs.buildPlatform = system;
                      system.stateVersion = "25.11";
                    }
                  )
                ];
              }).config.system.build.isoImage;
          };
        };
    }
