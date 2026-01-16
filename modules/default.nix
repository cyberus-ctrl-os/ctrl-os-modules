lib:
{
  developer = import ./developer.nix;
}
// lib.optionalAttrs (lib.versionAtLeast lib.version "25.11") {
  vms = import ./vms.nix;
}
