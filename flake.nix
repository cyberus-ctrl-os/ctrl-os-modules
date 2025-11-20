{
  description = "A collection of curated modules that work great with CTRL-OS (and NixOS)";

  # The inputs are only used for checks. We test this flake with
  # different Nixpkgs versions and with CTRL-OS in the CI.
  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz";
    preCommitHooksNix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-linux"
        "x86_64-linux"
      ];
      imports = [
        ./checks
        ./packages
      ]
      ++
        inputs.nixpkgs.lib.optionals (inputs.nixpkgs.lib.versionAtLeast inputs.nixpkgs.lib.version "25.11")
          [
            inputs.preCommitHooksNix.flakeModule
            ./checks/pre-commit.nix
          ];
      flake.nixosModules = import ./modules;

      perSystem =
        {
          pkgs,
          system,
          ...
        }:
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
          };

          formatter = pkgs.nixfmt-rfc-style;
        };
    };
}
