lib:
{
  developer = import ./developer.nix;
}
// lib.optionalAttrs (lib.versionAtLeast lib.version "25.11") {
  platform = import ./platform.nix;
  vms = import ./vms.nix;
}
