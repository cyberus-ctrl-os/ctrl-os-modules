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
                    { modulesPath, ... }:
                    {
                      imports = [
                        "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
                        self.nixosModules.platform
                        self.nixosModules.developer
                      ];

                      ctrl-os.developer.enable = true;
                      ctrl-os.platform = "nvidia-jetson-orin-nano";
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
