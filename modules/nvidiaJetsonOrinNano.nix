{ config, lib, ... }:
let
  cfg = config.ctrl-os.platforms.nvidia.jetsonOrinNano;
in
{
  options.ctrl-os.platforms.nvidia.jetsonOrinNano = {
    enable = lib.mkEnableOption "Enable the NVidia Jetson Orin Nano Platform Module";
  };

  config = lib.mkIf cfg.enable {
    # The Jetson Orin Nano UEFI allows boots with Device Tree only, switching
    # the UEFI option to ACPI bricks the device and makes a firmware flash
    # necessary to reset the option.
    hardware.deviceTree = {
      enable = true;
    };

    boot.initrd.availableKernelModules = [
      # Enable overall boot support by allowing access to memory controllers
      "i2c-tegra"
      # Enable PCIe support at boot time
      "nvme"
      "phy_tegra194_p2u"
      "pcie_tegra194"
      # Enable USB support for USB Boot
      "xhci-tegra"
      "phy-tegra-xusb"
    ];
  };
}
