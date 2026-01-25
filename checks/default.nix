{ self, inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      checks = {
        developer = pkgs.callPackage ./developer.nix { inherit (self) nixosModules; };
      }
      //
        inputs.nixpkgs.lib.optionalAttrs
          (
            inputs.nixpkgs.lib.versionAtLeast inputs.nixpkgs.lib.version "25.11"
            && pkgs.stdenv.isLinux
            # Package ‘vm-test-run-vms’ [...] is not available on the requested hostPlatform: hostPlatform.system = "aarch64-linux"
            && pkgs.stdenv.isx86_64
          )
          {
            vms = pkgs.callPackage ./vms.nix { inherit (self) nixosModules; };
          };

    };
}
