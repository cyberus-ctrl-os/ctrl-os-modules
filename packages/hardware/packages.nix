{
  pkgs,
  lib,
  ...
}:

lib.makeScope pkgs.newScope (
  self:
  let
    inherit (self)
      callPackage
      ;
  in
  # XXX package structure TBD
  {
    nvidia.tegra = callPackage ./nvidia/tegra { };
  }
)
