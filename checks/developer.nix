{ nixosModules, testers }:
testers.nixosTest {
  name = "developer";

  nodes.machine = {
    imports = [ nixosModules.developer ];

    ctrl-os.developer.enable = true;
  };

  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")
  '';
}
