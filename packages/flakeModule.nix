{ withSystem, inputs, self, ... }:
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
                    { lib, modulesPath, ... }:
                    {
                      imports = [
                        "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
                        self.nixosModules.hardware
                        self.nixosModules.developer
                      ];

                      ctrl-os.developer.enable = true;
                      ctrl-os.hardware.platform = "nvidia-jetson-orin-nano";

                      nixpkgs.buildPlatform = system;
                      system.stateVersion = lib.trivial.release;
                    }
                  )
                ];
              }).config.system.build.isoImage;
          };
        };
    }
