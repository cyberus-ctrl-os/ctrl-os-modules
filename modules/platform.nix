{ lib, ... }:
{
  options.ctrl-os.platform = lib.mkOption {
    type =
      with lib.types;
      nullOr (enum [
        "nvidia-jetson-orin-nano"
      ]);
    description = "The platform, we are running on.";
    default = null;
  };

  imports = [
    ./platforms/nvidiaJetsonOrinNano.nix
  ];
}
