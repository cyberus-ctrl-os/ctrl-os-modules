let
  # NOTE: This is not exposed in the arguments for this callPackage-pattern
  #       package, as it wouldn't work in overriding as expected.
  #       This version is used for `fetchurl` and for the `mkDerivation` later.
  # NOTE: This needs to be updated and match with the compatible `nvidia-oot` version.
  version = "36.5.0";
  sources = builtins.fromJSON (builtins.readFile ./nvidia-l4t-packages.json);
in
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  dpkg,
  systemd, # for udevadm

  coreutils,
  expat,
  libxcb,
  libxext,
  libX11,
  libGL,
  libdrm,
  libgbm,
  libffi,
  dbus,

  srcs ? builtins.listToAttrs (
    builtins.map
      (name: {
        inherit name;
        value = fetchurl sources."t234".${version}.packages.${name};
      })
      [
        "nvidia-l4t-core"
        "nvidia-l4t-3d-core"
        "nvidia-l4t-gbm"

        # egl-wayland
        "nvidia-l4t-wayland"
        "nvidia-l4t-libwayland-egl1"
        # Dep for `nvidia-l4t-wayland`
        "nvidia-l4t-libwayland-client0"
        # Dep for `nvidia-l4t-wayland`
        "nvidia-l4t-libwayland-server0"
        # vksc-core
        "nvidia-l4t-vulkan-sc"

        # libnvcuvid
        #"nvidia-l4t-multimedia"
        # libcuda
        "nvidia-l4t-cuda"
        # Deps for cuda
        "nvidia-l4t-nvsci"
        # libnvidia-ml
        "nvidia-l4t-nvml"

        # Configuration files that end-up being required
        "nvidia-l4t-init"
      ]
  ),
}:

# Listing found here:
#   - https://repo.download.nvidia.com/jetson/

stdenv.mkDerivation (finalAttrs: {
  pname = "nvidia-l4t";
  inherit version;

  unpackPhase = ''
    runHook preUnpack

    ${lib.concatStringsSep "\n" (
      # We can extract all packages at once, as they shouldn't conflict with eachother.
      # This way we don't need to bother with juggling all those directory structures,
      # it's already in the form of the installed system.
      lib.mapAttrsToList (name: src: ''
        printf '\n:: Extracting package %q\n' "${name}"
        dpkg -x "${src}" ./
      '') srcs
    )}

    runHook postUnpack
  '';

  # These dependencies are patchelf'd with the autoPatchelfHook.
  # Their runpaths are also being added unconditionally for `dlopen()` reasons.
  runtimeDependencies = [
    stdenv.cc.cc
    expat
    libxcb
    libxext
    libX11
    libGL
    libdrm
    libgbm
    libffi
    # Used at runtime by `libnvidia-*glcore.so`...
    dbus.lib
  ];

  buildInputs =
    # Dependencies being patchelf'd, to satisfy autoPatchelfHook
    finalAttrs.runtimeDependencies;

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    systemd
  ];

  buildPhase = ''
    args=(
      # Fix style issues with the rules.
      # This is used to ensure further patches are "proper".
      --replace-fail '" GOTO=' '", GOTO='
      --replace-fail '" OWNER=' '", OWNER='
      --replace-fail '" GROUP=' '", GROUP='
      --replace-fail '" MODE=' '", MODE='
      --replace-fail '" KERNEL==' '", KERNEL=='

      # Patch uaccess on `video` group device nodes.
      --replace-fail 'GROUP="video"' 'GROUP="video", TAG+="uaccess"'

      # replace hardcoded utils
      --replace-fail "/bin/mknod" "${lib.getExe' coreutils "mknod"}"
    )
    substituteInPlace etc/udev/rules.d/99-tegra-devices.rules "''${args[@]}"

    # Check this is valid, and also for style.
    udevadm verify --resolve-names=late \
      etc/udev/rules.d/99-tegra-devices.rules
  '';

  installPhase = ''
    runHook preInstall

    for el in usr/lib/aarch64-linux-gnu/*; do
      if test -L "$el"; then
        rm -v "$el"
      fi
    done
    rm -v usr/lib/aarch64-linux-gnu/*/ld.so.conf

    mkdir -vp $out/{lib,share}
    mv -vt $out/share usr/share/doc
    mv -vt $out/lib usr/lib/aarch64-linux-gnu/*/*
    mv -vt $out/lib usr/lib/xorg

    mkdir -vp $out/share/egl/egl_external_platform.d/
    mv -t $out/share/egl/egl_external_platform.d/ usr/share/egl/egl_external_platform.d/nvidia_gbm.json

    mkdir -vp "$out/lib/udev/rules.d"
    # NOTE: uaccess tags require filenames to lexicographically sort before `73-seat-late.rules`.
    mv -v etc/udev/rules.d/99-tegra-devices.rules $out/lib/udev/rules.d/70-tegra-devices.rules

    (
      set -x

      cd $out/lib

      mkdir -vp ../share/vulkan/icd.d
      mv -v nvidia_icd.json ../share/vulkan/icd.d/nvidia_icd.aarch64.json
      substituteInPlace ../share/vulkan/icd.d/nvidia_icd.aarch64.json \
        --replace-fail "libGLX_nvidia.so.0" "$PWD/libGLX_nvidia.so.0"

      mkdir -vp ../share/glvnd/egl_vendor.d/
      mv -v nvidia.json ../share/glvnd/egl_vendor.d/30_nvidia.json
      substituteInPlace ../share/glvnd/egl_vendor.d/30_nvidia.json \
        --replace-fail "libEGL_nvidia.so.0" "$PWD/libEGL_nvidia.so.0"

      substituteInPlace ../share/egl/egl_external_platform.d/nvidia_gbm.json \
        --replace-fail "libnvidia-egl-gbm.so.1" "$PWD/libnvidia-egl-gbm.so.1"

      mkdir -p gbm
      # Fixup libnvidia-allocator links we broke
      for lib in tegra-udrm_gbm.so tegra_gbm.so nvidia-drm_gbm.so; do
        mv -t gbm "$lib"
        ln -fs ../libnvidia-allocator.so "gbm/$lib"
      done
    )

    runHook postInstall

    # Work around autoPatchelfHook idiosyncrasy...
    # We are not handling the whole patching ourselves since we want to rely
    # on the autoPatchelfHook "missing dependencies" support.
    fixupNvidiaL4T() {
      (
        set -x
        cd $out/lib

        rpath="$(
          # Add "self" to the rpath
          printf "${placeholder "out"}/lib"
          # And all runtimeDependencies
          printf ":%s" ''${runtimeDependenciesArray[@]/%//lib}
        )"

        # Apparently `runtimeDependencies` and `appendRunPaths` are only
        # effective for .so where the autoPatchelfHook changed the .so...
        # Let's make sure any `dlopen`, such as found in `libnvos`, works.
        for lib in $(find -type f -name '*.so*'); do
          patchelf --add-rpath "$rpath" "$lib"
        done
      )
    }

    # This needs to run *after* the autoPatchelfHook...
    # This is why we're adding this "late".
    printf "Adding fixupNvidiaL4T hook\n"
    postFixupHooks+=( fixupNvidiaL4T )
  '';

  # Don't strip "unnecessary" rpath values out
  dontPatchELF = true;
  # Also don't even try stripping vendor libraries.
  dontStrip = true;

  passthru = {
    inherit sources;
  };

  meta = {
    licenses = [
      lib.licenses.unfree
    ];
  };
})
