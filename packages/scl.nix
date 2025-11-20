{
  lib,
  rustPlatform,
  protobuf,
}:
rustPlatform.buildRustPackage {
  pname = "scl-management";
  version = "0.1.0";
  src = fetchGit {
    url = "https://gitlab.com/alasca.cloud/scl/scl-management.git";
    rev = "76f0a8cd5ae0e4ecdfd28acaf11749e522dd3335";
  };
  cargoHash = "sha256-KS2/0UdJoWdpS3Tyx9dh6JtX9u/+O6TqOZmY2D7thVo=";
  buildInputs = [ ];
  nativeBuildInputs = [ protobuf ];
  doCheck = false;

  meta = {
    description = "Separation Context Layer";
    license = lib.licenses.gpl2Only;
    maintainers = with lib.maintainers; [ ctrl-os ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
