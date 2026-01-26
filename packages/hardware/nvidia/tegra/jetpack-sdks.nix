# The compatibility matrix can be found here:
#  - https://developer.nvidia.com/embedded/jetson-linux-archive
{
  lib,
  fetchurl,
}:

rec {
  versions = {
    "36.4.4" = fetchurl {
      version = "36.4.4";
      url = "https://developer.nvidia.com/downloads/embedded/l4t/r36_release_v4.4/release/Jetson_Linux_r36.4.4_aarch64.tbz2";
      hash = "sha256-ps4RwiEAqwl25BmVkYJBfIPWL0JyUBvIcU8uB24BDzs=";
      meta.nvidiaDriverLicenseAgreement = "https://developer.download.nvidia.com/embedded/L4T/r36_Release_v4.4/release/Tegra_Software_License_Agreement-Tegra-Linux.txt";
      meta.license = [ lib.licenses.unfree ];
    };
  };

  default = {
    # NOTE: Version 38.* currently does not support Jetson Orin systems.
    orin = versions."36.4.4";
  };
}
