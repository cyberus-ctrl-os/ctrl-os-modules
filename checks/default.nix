{ self, ... }:
{
  perSystem =
    { pkgs, ... }:
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

    };
}
