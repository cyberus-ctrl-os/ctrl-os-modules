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
          (inputs.nixpkgs.lib.versionAtLeast inputs.nixpkgs.lib.version "25.11")
          {
            vms = pkgs.callPackage ./vms.nix { inherit (self) nixosModules; };
          };

    };
}
