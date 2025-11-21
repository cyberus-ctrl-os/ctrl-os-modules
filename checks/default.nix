{ self, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      checks = {
        developer = pkgs.callPackage ./developer.nix { inherit (self) nixosModules; };
      };

    };
}
