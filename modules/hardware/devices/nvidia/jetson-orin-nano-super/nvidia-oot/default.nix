{
  lib,
  fetchFromGitLab,
  kernel,
  kernelModuleMakeFlags ? kernel.makeFlags,

  # `srcs` is exposed in `passthru` to allow easily overriding `srcs`.
  #
  #     let p = linuxPackages.nvidia-oot; in
  #     p.override {
  #        srcs = p.srcs // {
  #          linux-nv-oot = builtins.fetchGit .../linux-nv-oot;
  #        };
  #     })
  srcs ?
    let
      rev = "rel-36_eng_2026-01-04";
      repos = {
        "linux-hwpm" = "sha256-LrCtuQIbHxBibJaMnrNYEAegtezUDUPGiHJDW+0qHA8=";
        "linux-nvgpu" = "sha256-zvnTygjF8BUNxaqcU4Mt6kAwngFpArM5timpjw074uQ=";
        "linux-nv-oot" = "sha256-Vt4ef0GIFpk34IPCIL7/R6Jsssd90GXLKonIY8P4e5s=";
      };
    in
    builtins.mapAttrs (
      repo: hash:
      fetchFromGitLab {
        owner = "nvidia";
        repo = "nv-tegra/${repo}";
        inherit rev hash;
      }
    ) repos,
}:

kernel.stdenv.mkDerivation (finalAttrs: {
  pname = "nvidia-oot";

  # Get from the `srcs`, for easier overriding.
  version =
    srcs.linux-nv-oot.shortRev or srcs.linux-nv-oot.rev or srcs.linux-nv-oot.tag
      or (builtins.throw "Source `rev` or `tag` couldn't be detected from `srcs`.");

  unpackPhase = ''
    runHook preUnpack

    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: src: ''
        printf '\n:: Copying %q to workspace\n' "${name}"
        mkdir -p ./${name}
        cp -rt ./${name} ${src}/*
        chmod -R +w ./${name}
      '') srcs
    )}
    export workspace="$PWD"

    runHook postUnpack
  '';

  nativeBuildInputs = kernel.moduleBuildDependencies;

  postPatch = ''
    printf '\n:: Disabling nvethernet driver...\n'
    # Not needed on supported hardware, requires additional repository setup.
    echo "# disabled" > "$workspace/linux-nv-oot/drivers/net/ethernet/nvidia/nvethernet/Makefile"
  '';

  configurePhase = ''
    # All phases are fine with parallel building.
    makeFlagsArray+=("-j$NIX_BUILD_CORES")

    runHook preConfigure

    printf '\n :: Running the "conftest" suite from the vendor\n'

    # We're doing this weird thing where we copy the source over because the
    # `conftest.h` file needs to live in an `nvidia` folder. That's how the
    # vendor sets it up, so we don't have much of a choice here.
    # The vendor expects the builds to happen where the source lives.
    # Things break horribly otherwise.

    # The `NVIDIA_CONFTEST` location can be pretty much arbitrary.
    export NVIDIA_CONFTEST="$workspace/nvidia-conftest"
    mkdir -vp "$NVIDIA_CONFTEST"
    # Copy the project over with the required `nvidia` name, to make `<nvidia/conftest.h>`.
    cp -vr "$workspace/linux-nv-oot/scripts/conftest" "$NVIDIA_CONFTEST/nvidia"

    make $makeFlags "''${makeFlagsArray[@]}" \
      obj="$NVIDIA_CONFTEST/nvidia" \
      src="$NVIDIA_CONFTEST/nvidia" \
      ARCH="${kernel.karch}" \
      NV_KERNEL_SOURCES="${kernel.dev}/lib/modules/${kernel.modDirVersion}/source" \
      NV_KERNEL_OUTPUT="${kernel.dev}/lib/modules/${kernel.modDirVersion}/build" \
      EXTRA_CFLAGS=${
        lib.escapeShellArgs [
          # We need to add back the `-std` used by the kernel, as with GCC 15 the
          # `-std` GCC uses changed to `c23`, and the kernel uses patterns that
          # fail with `c23`. This is only needed for conftest, as the other parts
          # will properly use the kernel tooling.
          # NOTE that NIX_CFLAGS_COMPILE are ineffective due to https://github.com/NixOS/nixpkgs/issues/484935.
          "-std=gnu11"
        ]
      } \
      -f "$NVIDIA_CONFTEST/nvidia/Makefile"

    runHook postConfigure
  '';

  makeFlags = kernelModuleMakeFlags ++ [
    # Call the kernel's build tooling
    # The `M=` variable is the chosen build entrypoint (see buildPhase).
    "-C"
    "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"

    # Variables needed by the vendor tooling.
    # Tip:
    # Use the following command from the kernel_oot_modules_src folder in the BSP.
    #    $ grep --no-filename -E --only-matching -RIi '\bsrctree\.[a-zA-Z0-9_-]+' | sort -u
    "srctree.hwpm=$(workspace)/linux-hwpm"
    "srctree.nvconftest=$(NVIDIA_CONFTEST)"
    "srctree.nvidia=$(workspace)/linux-nv-oot"
    "srctree.nvidia-oot=$(workspace)/linux-nv-oot"
    # "srctree.nvgpu=" # The nvgpu Makefile handles setting this value
    # "srctree.host1x=" # unused. NOTE: from a leftover(?) comment. Instead, the `srctree.nvidia` variable, is used.
    # "srctree.nvmap=" # unused. NOTE: refers to an "upstream" nvmap driver. When `CONFIG_NVGPU_NVMAP_NEXT=y`

    # Kernel configuration overrides.
    "CONFIG_TEGRA_OOT_MODULE=m" # Enable Tegra out-of-tree modules

    # NVIDIA overrides
    # Disable kernel modules that are part of the broader BSP.
    "NV_OOT_BLUETOOTH_REALTEK_SKIP_BUILD=y"
    "NV_OOT_REALTEK_RTL8822CE_SKIP_BUILD=y"
    "NV_OOT_REALTEK_RTL8852CE_SKIP_BUILD=y"
    "NV_OOT_REALTEK_R8168_SKIP_BUILD=y"
    "NV_OOT_REALTEK_R8126_SKIP_BUILD=y"
    # And this one which is simply not needed.
    "NV_OOT_BLOCK_TEGRA_VIRT_STORAGE_SKIP_BUILD=y"
  ];

  buildFlags = [
    "modules"
  ];

  # NOTE: This `buildPhase` *string* is re-used (after overrides) as installPhase with
  #       build-related keywords substituted for install-related keywords.
  buildPhase = ''
    runHook preBuild

    # There are multiple build phases that need to be combined in a single build.
    # The intermediate results and repos are required by some steps, for example from hwpm.

    # This helper makes it easier to deal with the different builds.
    _make() {
      local flagsArray=()
      concatTo flagsArray makeFlags makeFlagsArray buildFlags buildFlagsArray

      # Use `set -x` to show the make invocation.
      (PS4=" $ "; set -x; make "''${flagsArray[@]}" "$@")
    }

    # Keep track of intermediary module symbols created during the build.
    KBUILD_EXTRA_SYMBOLS=""
    export KBUILD_EXTRA_SYMBOLS

    printf '\n :: Building hwpm\n'
    _make "M=$workspace/linux-hwpm/drivers/tegra/hwpm"
    KBUILD_EXTRA_SYMBOLS+=" $workspace/linux-hwpm/drivers/tegra/hwpm/Module.symvers"

    printf '\n :: Building linux-nv-oot\n'
    _make "M=$workspace/linux-nv-oot"
    KBUILD_EXTRA_SYMBOLS+=" $workspace/linux-nv-oot/Module.symvers"

    printf '\n :: Building nvgpu\n'
    _make "M=$workspace/linux-nvgpu/drivers/gpu/nvgpu"

    runHook postBuild
  '';

  installFlags = [
    "INSTALL_MOD_PATH=${placeholder "out"}"
  ];
  installTargets = [
    "modules_install"
  ];

  installPhase =
    let
      replacements = {
        "buildFlags" = "installFlags installTargets";
        "buildPhase" = "installPhase";
        "postBuild" = "postInstall";
        "preBuild" = "preInstall";
        "Building" = "Installing";
      };
      from = builtins.attrNames replacements;
      to = builtins.attrValues replacements;
    in
    builtins.replaceStrings from to finalAttrs.buildPhase;

  passthru = {
    inherit srcs;
  };

  meta = {
    # Unclear if this supports anything else than AArch64 Tegra platforms
    platforms = [ "aarch64-linux" ];
    license = [
      # Tip:
      # Use the following command to quickly and dirtily collect information.
      #     $ grep --no-filename -ERI '^[^a-zA-Z]+SPDX-' | sed -E -e 's;\*/;;g' -e 's;\([cC]\);(C);g' -e 's;([0-9]{4}([,-]?))+;YYYY;g' -e 's;^\s*(#|\*|/\*|//) *;# ;g' -e 's;\s+; ;g' -e 's;\s+$;;' | sort -u
      # These files with an "all rights reserved" SPDX identifier are verified to have had a license identifier using:
      #     $ grep --files-without-match -i 'spdx-license-identifier' $(grep -RIil 'FileCopyright')

      # hwpm
      # SPDX-License-Identifier: GPL-2.0
      # linux-nv-oot
      # SPDX-License-Identifier: GPL-2.0
      # SPDX-License-Identifier: GPL-2.0-only
      # SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
      # SPDX-License-Identifier: (GPL-2.0 OR BSD-2-Clause)
      # nvgpu:
      # SPDX-License-Identifier: GPL-2.0
      # SPDX-License-Identifier: GPL-2.0-only
      # SPDX-License-Identifier: GPL-2.0-only OR MIT
      # SPDX-License-Identifier: GPL-2.0-or-later
      lib.licenses.gpl2Only

      # linux-nv-oot
      # SPDX-License-Identifier: MIT
      # nvgpu:
      # SPDX-License-Identifier: MIT
      lib.licenses.mit

      # linux-nv-oot
      # SPDX-License-Identifier: BSD-3-Clause
      lib.licenses.bsd3
    ];

    # Vendor supports up to 6.15 as of 2026-01-04.
    broken = lib.versionAtLeast kernel.version "6.16";
  };
})
