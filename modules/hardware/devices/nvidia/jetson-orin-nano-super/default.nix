{ config, lib, ... }:

let
  cfg = config.ctrl-os.hardware.devices.nvidia-jetson-orin-nano-super;
in
{
  options = {
    ctrl-os.hardware.devices.nvidia-jetson-orin-nano-super = {
      enableOotModules = lib.mkEnableOption "the NVIDIA Out-Of-Tree kernel modules" // {
        default = true;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.hostPlatform = "aarch64-linux";

    boot.initrd.availableKernelModules = [
      # Enable PCIe support at boot time
      "phy_tegra194_p2u"
      "pcie_tegra194"
      # Enable USB support for USB Boot
      "xhci-tegra"
      "phy-tegra-xusb"
    ];

    boot.extraModulePackages = lib.mkMerge [
      (lib.mkIf cfg.enableOotModules [
        (config.boot.kernelPackages.callPackage ./nvidia-oot { })
      ])
    ];
  };
}
