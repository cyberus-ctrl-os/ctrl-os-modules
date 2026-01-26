{ lib, ... }:
{
  options.ctrl-os.hardware.platform = lib.mkOption {
    type =
      with lib.types;
      nullOr (enum [
        "nvidia-jetson-orin-nano"
      ]);
    description = "Enables drivers and packages for the given board or system.";
    default = null;
  };

  imports = [
    ./nvidia-jetson-orin-nano.nix
  ];
}
