{ ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages = {
        scl = pkgs.callPackage ./scl.nix { };
      };
    };
}
