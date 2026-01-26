{
  pkgs,
  nixosModules,
}:

let
  check = import ../lib/check-modules-no-ops.nix {
    inherit pkgs;
    modules = nixosModules;
  };
in
builtins.seq check.result (
  (pkgs.writeText "modules-check" (builtins.toJSON check.result)) // { inherit check; }
)
