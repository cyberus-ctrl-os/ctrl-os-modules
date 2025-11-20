{ self, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      # We mostly check that the module evaluates.
      checks.developer = pkgs.testers.nixosTest {
        name = "developer";

        nodes.machine = {
          imports = [ self.nixosModules.developer ];

          ctrl-os.developer.enable = true;
        };

        testScript = ''
          start_all()
          machine.wait_for_unit("multi-user.target")
        '';
      };

      pre-commit =
        let
          styleCheckRequired = lib.versionAtLeast lib.version "25.11";
        in
        {
          check.enable = lib.warnIfNot (
            styleCheckRequired
          ) "Style Check disabled, because we do not use the latest nixpkgs version" styleCheckRequired;
          settings = {
            package = pkgs.pre-commit;
            excludes = [
            ];
            hooks = {
              shfmt = {
                enable = true;
                raw.entry = " --indent 2";
              };
              nixfmt-rfc-style.enable = true;
              deadnix.enable = true;
              shellcheck.enable = true;
              trim-trailing-whitespace.enable = true;
              check-executables-have-shebangs.enable = true;
            };
          };
        };
    };
}
