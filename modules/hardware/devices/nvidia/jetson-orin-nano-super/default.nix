{
  config,
  lib,
  pkgs,
  ...
}:

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
      # Reminder device enablement modules should not set the unfree software option.
      # The module *must* fail with the unfree software error.
      # The user must make the informed decision about enabling unfree software.
      enableHardwareAcceleration = lib.mkEnableOption "the NVIDIA proprietary graphical and ML drivers";
      quirks = {
        # Enabled by default since it's cheap.
        addDebugUserGroup =
          lib.mkEnableOption "adding the `debug` user group, which is used in vendor udev configuration"
          // {
            default = true;
          };
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

      {
        boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_6_12;
      }

      (lib.mkIf cfg.enableOotModules {
        boot.extraModulePackages = [
          config.boot.kernelPackages.nvidia-oot
        ];
      })

      (lib.mkIf cfg.quirks.addDebugUserGroup {
        users.groups = {
          # Works around these warnings in system logs:
          #     /etc/udev/rules.d/99-tegra-devices.rules:00 Unknown group 'debug', ignoring.
          debug = { };
        };
      })

      (lib.mkIf cfg.enableHardwareAcceleration {
        services.udev.packages = [
          pkgs.nvidia-jetson-orin-nano-super.nvidia-l4t
        ];
        hardware.firmware = lib.mkAfter [
          pkgs.nvidia-jetson-orin-nano-super.nvidia-l4t-firmware
        ];
        hardware.graphics.extraPackages = [
          pkgs.nvidia-jetson-orin-nano-super.nvidia-l4t
        ];
        boot.kernelModules = [
          "tegra_drm"
          # This *cannot* be loaded with `tegra_drm` or else it breaks.
          # It will be loaded as needed.
          # "nvidia_drm"
        ];
        boot.extraModprobeConfig = lib.mkMerge [
          # Without `modeset`, the X11 driver will fail to work.
          # This is the vendor-suggested configuration.
          "options nvidia_drm modeset=1 fbdev=1"
        ];
        services.xserver = {
          # Use the `nvidia` driver for `tegra` kernel driver matches.
          config = ''
            Section "OutputClass"
              Identifier "nvidia"
              MatchDriver "tegra"
              Driver "nvidia"
            EndSection
          '';
          # NOTE: videoDrivers cannot be used.
          # Enabling `"nvidia"` within it uses the non-l4t NVIDIA driver.
          # Instead we force the driver list to ensure only this one is used.
          drivers = lib.mkForce (
            lib.singleton {
              name = "nvidia";
              modules = [ pkgs.nvidia-jetson-orin-nano-super.nvidia-l4t ];
              display = true;
              deviceSection = ''
                Option "AllowEmptyInitialConfiguration" "true"
              '';
            }
          );
        };
      })
    ]
  );
}
