{ ... }:
{
  perSystem =
    {
      config,
      pkgs,
      ...
    }:
    {
      # Common developer tooling. We also use this in the CI.
      devShells.default = pkgs.mkShell {
        packages = config.pre-commit.settings.enabledPackages;
        shellHook = config.pre-commit.installationScript;
      };

      pre-commit = {
        check.enable = true;
        settings = {
          package = pkgs.pre-commit;
          excludes = [
          ];
          hooks = {
            shfmt = {
              enable = true;
              raw.entry = " --indent 2";
            };
            nixfmt.enable = true;
            deadnix.enable = true;
            shellcheck.enable = true;
            trim-trailing-whitespace.enable = true;
            check-executables-have-shebangs.enable = true;
          };
        };
      };
    };
}
