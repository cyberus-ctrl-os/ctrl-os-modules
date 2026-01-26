{
  nixpkgs.hostPlatform = "aarch64-linux";

  boot.initrd.availableKernelModules = [
    # Enable PCIe support at boot time
    "phy_tegra194_p2u"
    "pcie_tegra194"
    # Enable USB support for USB Boot
    "xhci-tegra"
    "phy-tegra-xusb"
  ];
}
