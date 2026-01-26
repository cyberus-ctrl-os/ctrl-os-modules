{ lib, ... }:

let
  inherit (import ../../../lib { inherit lib; })
    getVendorsModules
    ;
  developerModules = getVendorsModules ./.;
in
{
  imports = builtins.attrValues developerModules;
}
