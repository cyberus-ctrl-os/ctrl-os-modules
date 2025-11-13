{
  description = "A collection of curated modules that work great with CTRL-OS (and NixOS)";

  # The inputs are only used for checks. We test this flake with
  # different Nixpkgs versions and with CTRL-OS in the CI.
  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz";
  };

  outputs =
    inputs@{ self, ... }:
    {
      nixosModules = import ./modules;

      # For now, tests run only on x86_64. Will expand a bit later.
      checks.x86_64-linux = import ./checks {
        pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
        modules = self.nixosModules;
      };

      # Common developer tooling. We also use this in the CI.
      devShells.x86_64-linux.default =
        let
          pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
        in
        pkgs.mkShell {
          packages = [ pkgs.nixpkgs-fmt ];
        };
    };
}
