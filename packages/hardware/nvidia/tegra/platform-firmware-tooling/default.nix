{
  lib,
  stdenv,
  runtimeShell,
  writeShellScript,
  libarchive,

  coreutils,
  dtc,
  gcc, # for the C pre-processor, for dtc...
  gnused,
  python3,
  libxml2, # for xmllint

  # Path to the SDK *archive*.
  sdk,
}:

let
  path = lib.makeBinPath [
    (python3.withPackages (
      pp: with pp; [
        pyyaml
      ]
    ))
    coreutils
    dtc
    gcc
    gnused
    libxml2
  ];

  # This wrapper is used to make the NVIDIA tooling happier.
  # It *really really* wants to have write-access to the tooling's data folders.
  # So let's make up a fresh new folder every time.
  wrapper = writeShellScript "nvidia-host-pc-tool-wrapper" ''
    set -e
    set -u
    export PS4=" $ "

    export PATH=${lib.escapeShellArg path}:"$PATH"

    sdk="$(readlink -f "''${BASH_SOURCE[0]%/*}")"
    original_pwd="$PWD"
    dir="$(mktemp -p "''${TMPDIR:-}" -d "nvidia-flashing.XXXXXXXXXX")"

    echo "Going to temp runtime dir: '$dir'"
    cd "$dir"
    cp --no-preserve=ownership -r "$sdk"/* ./
    chmod -R a+wr .

    (
    set -x
    "$@"
    ) || :

    ret=$?

    echo "Cleaning-up..."
    rm -rf "$dir"

    exit $ret
  '';
in
stdenv.mkDerivation (finalAttrs: {
  pname = "nvidia-host-platform-firmware-tooling";
  version = finalAttrs.sdk.version;

  inherit sdk;

  nativeBuildInputs = [
    libarchive
  ];

  # Handle unpacking ourselves, the SDK is unwieldy.
  dontUnpack = true;

  installPhase = ''
    patterns=(
      "Linux_for_Tegra/bootloader"
      "Linux_for_Tegra/kernel/dtb"
      "Linux_for_Tegra/*.sh"
      "Linux_for_Tegra/*.cfg"
      "Linux_for_Tegra/*.conf"
      "Linux_for_Tegra/*.conf.common"
    )
    mkdir -vp $out/bin

    # NOTE: We are expanding '$out' in the script by design.
    cat > $out/bin/flash <<EOF
    #!${runtimeShell}
    exec "$out/sdk/exec-wrapper.sh" "./flash.sh" "\$@"
    EOF

    cp ${./reflash-bios.sh} $out/bin/reflash-bios
    patchShebangs $out/bin/reflash-bios
    substituteInPlace $out/bin/reflash-bios \
      --replace-fail @out@ "$out"

    chmod +x $out/bin/*

    mkdir -vp $out/sdk
    cp -v ${wrapper} $out/sdk/exec-wrapper.sh
    (
    cd $out/sdk
    bsdtar --verbose \
      --strip-components 1 \
      --file "$sdk" \
      --extract \
      "''${patterns[@]}"

    # Cleanup unneeded large files...
    rm bootloader/*.deb
    rm bootloader/*initrd.img

    # Some fixups for *really bad* dependency checking implementation.
    substituteInPlace flash.sh \
      --replace-fail "check_xmllint __XMLLINT_BIN" "__XMLLINT_BIN=${lib.getExe' libxml2 "xmllint"}"

    # Ensure scripts will run
    patchShebangs flash.sh bootloader/*.{sh,py}
    )
  '';

  meta = {
    mainProgram = "reflash-bios";
  };
})
