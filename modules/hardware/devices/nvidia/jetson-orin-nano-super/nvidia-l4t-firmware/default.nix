{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  nvidia-l4t,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "nvidia-l4t-firmware";
  inherit (nvidia-l4t) version;

  src = fetchurl nvidia-l4t.sources."t234".${finalAttrs.version}.packages.nvidia-l4t-firmware;
  unpackPhase = ''
    runHook preUnpack

    printf '\n:: Extracting package %q\n' "${finalAttrs.pname}"
    dpkg -x "$src" ./

    runHook postUnpack
  '';

  nativeBuildInputs = [
    dpkg
  ];

  installPhase = ''
    runHook preInstall

    # Drop misc. BSP-provided firmware.
    (
      cd lib/firmware
      rm -rfv brcm* rtl* nv-{BT,WIFI}-Version
    )

    mkdir -vp $out/lib
    mv -vt $out/lib lib/firmware

    runHook postInstall
  '';

  dontPatchELF = true;
  dontStrip = true;

  meta = {
    licenses = [
      lib.licenses.unfree
    ];
  };
})
