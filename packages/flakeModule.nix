{ ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages = import ./default.nix { inherit pkgs; };
    };
}
