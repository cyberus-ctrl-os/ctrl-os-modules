{
  callPackage,
  nvidia,
}:

{
  jetpack-sdks = callPackage ./jetpack-sdks.nix { };

  developer-tools = {
    orin = {
      platform-firmware-tooling = callPackage ./platform-firmware-tooling {
        sdk = nvidia.tegra.jetpack-sdks.default.orin;
      };
    };
  };
}
