{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.ctrl-os.hardware.developer.nvidia.tegra;
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    ;

  # Makes an "enable" option that defaults to the `cfg.enable` state.
  mkDefaultEnable =
    description:
    (lib.mkEnableOption description)
    // {
      default = cfg.enable;
      defaultText = "config.ctrl-os.hardware.developer.nvidia.tegra.enable";
    };
in
{
  options.ctrl-os.hardware.developer.nvidia.tegra = {
    enable = mkEnableOption "configuration on a host system for working with Tegra devices";
    enableUdevRules = mkDefaultEnable "udev rules to communicate with the USB download mode for recovery";
  };

  config = mkMerge [
    (mkIf cfg.enableUdevRules {
      services.udev.packages = lib.singleton (
        pkgs.writeTextFile rec {
          name = "usb-nvidia-hw.rules";
          text = ''
            SUBSYSTEM!="usb", GOTO="end_rules"

            # Orin
            ATTRS{idVendor}=="0955", ATTRS{idProduct}=="7523", TAG+="uaccess"

            LABEL="end_rules"
          '';
          destination = "/etc/udev/rules.d/70-${name}";
        }
      );
    })
  ];
}
