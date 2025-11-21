{ self, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      checks = {
        developer = pkgs.callPackage ./developer.nix { inherit (self) nixosModules; };
        vms = pkgs.callPackage ./vms.nix { inherit (self) nixosModules; };
      };

    };
}
