{
  lib,
  buildLinux,
  fetchFromGitLab,
  kernelPatches,
  ...
# This needs to forward additional `.override` args to `buildLinux`.
# See `nixos/modules/system/boot/kernel.nix`.
# This is how e.g. `boot.kernelPatches` is implemented.
}@args:

let
  tag = "jetson_36.5";
in
buildLinux (
  args
  // {
    version = "5.15.185-${tag}";
    src = fetchFromGitLab {
      owner = "nvidia";
      repo = "nv-tegra/3rdparty/canonical/linux-jammy";
      inherit tag;
      hash = "sha256-YYp1e641H+ELtke94PNIVvEXDKW9yNVS++Pkz69r1zU=";
    };
    inherit kernelPatches;
    structuredExtraConfig = {
      LOCALVERSION = lib.kernel.freeform ''-${tag}'';
      # Driver build is broken from backport of new drivers.
      # ../drivers/media/pci/intel/ipu6/../ipu-dma.c:53:17: error: implicit declaration of function 'clflush_cache_range'; did you mean 'flush_cache_range'? [-Werror=implicit-function-declaration]
      VIDEO_INTEL_IPU6 = lib.kernel.no;

      FB_SIMPLE = lib.kernel.yes;
      # SIMPLEDRM **must** be disabled for the X11 driver.
      DRM_SIMPLEDRM = lib.mkForce lib.kernel.no;

      # XZ compressed firmware load is not enabled if not specified.
      FW_LOADER_COMPRESS = lib.kernel.yes;
      FW_LOADER_COMPRESS_XZ = lib.kernel.yes;
    };
  }
)
