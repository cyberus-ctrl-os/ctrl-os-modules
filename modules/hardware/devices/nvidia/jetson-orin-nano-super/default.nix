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
      enableStage1KernelModules =
        lib.mkEnableOption "use of storage and necessary kernel modules in stage-1"
        // {
          default = true;
        };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        nixpkgs.hostPlatform = "aarch64-linux";

        # We can add the proprietary packages to the overlay even without enabling the
        # *configuration* for proprietary packages. This leaves it up to the end-user
        # to use those proprietary packages.
        nixpkgs.overlays = [
          (final: super: {
            kernelPackagesExtensions = (super.kernelPackagesExtensions or [ ]) ++ [
              (kFinal: _kSuper: {
                nvidia-oot = kFinal.callPackage ./nvidia-oot { };
              })
            ];
            nvidia-jetson-orin-nano-super = {
              nvidia-l4t = final.callPackage ./nvidia-l4t { };
              nvidia-l4t-firmware = final.callPackage ./nvidia-l4t-firmware {
                inherit (final.nvidia-jetson-orin-nano-super)
                  nvidia-l4t
                  ;
              };
              nvidia-l4t-kernelPackages = final.linuxPackagesFor final.nvidia-jetson-orin-nano-super.nvidia-l4t-kernel;
              nvidia-l4t-kernel = final.callPackage ./nvidia-l4t-kernel {
                kernelPatches = [
                  final.linuxKernel.kernelPatches.bridge_stp_helper
                  final.linuxKernel.kernelPatches.request_key_helper
                ];
              };
            };
          })
        ];
      }

      (lib.mkIf cfg.enableStage1KernelModules {
        boot.initrd.availableKernelModules = [
          # Enable PCIe support at boot time
          "phy_tegra194_p2u"
          "pcie_tegra194"
          # Enable USB support for USB Boot
          "xhci-tegra"
          "phy-tegra-xusb"
        ];
      })

      (lib.mkIf cfg.enableOotModules {
        boot.extraModulePackages = [
          config.boot.kernelPackages.nvidia-oot
        ];
      })
    ]
  );
}
