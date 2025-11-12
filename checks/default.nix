{ pkgs, modules }:
{
  # We mostly check that the module evaluates.
  developer = pkgs.testers.nixosTest {
    name = "developer";

    nodes.machine = {
      imports = [ modules.developer ];

      ctrl-os.developer.enable = true;
    };

    testScript = ''
      start_all()
      machine.wait_for_unit("multi-user.target")
    '';
  };
}
