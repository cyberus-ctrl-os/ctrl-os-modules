{ nixosModules, testers }:
testers.nixosTest {
  name = "profiles.developer";

  nodes.machine = {
    imports = [ nixosModules.profiles ];

    ctrl-os.profiles.developer.enable = true;
  };

  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")
  '';
}
