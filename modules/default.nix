lib:
{
  developer = import ./developer.nix;
}
// lib.optionalAttrs (lib.versionAtLeast lib.version "25.11") {
  hardware = import ./hardware;
  vms = import ./vms.nix;
}
