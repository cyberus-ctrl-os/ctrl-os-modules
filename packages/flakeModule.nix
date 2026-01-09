{ inputs, self, ... }:
let
  mkJetsonOrinNanoInstallerIso =
    modulesPathModule:
    (inputs.nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        (
          { modulesPath, ... }:
          {
            imports = [
              "${modulesPath}/${modulesPathModule}"
              self.nixosModules.nvidiaJetsonOrinNano
              self.nixosModules.developer
            ];

            ctrl-os.developer.enable = true;
            ctrl-os.platforms.nvidia.jetsonOrinNano.enable = true;
            system.stateVersion = "25.11";
          }
        )
      ];
    }).config.system.build.isoImage;
in
{
  perSystem =
    { ... }:
    {
      packages = {
        jetsonOrinNanoInstaller = mkJetsonOrinNanoInstallerIso "installer/cd-dvd/installation-cd-minimal.nix";
      };
    };
}
