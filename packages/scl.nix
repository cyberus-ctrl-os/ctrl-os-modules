{
  cloud-utils,
  fetchFromGitLab,
  lib,
  openssl,
  protobuf,
  rustPlatform,
}:
rustPlatform.buildRustPackage {
  pname = "scl-management";
  version = "0.1.0";
  src = fetchFromGitLab {
    owner = "alasca.cloud";
    repo = "scl/scl-management";
    rev = "main";
    hash = "sha256-k47sHYDWv5TZv8Sws/U4N74uN4Y4f5Hs5TQ++UnKQoQ=";
  };
  cargoHash = "sha256-i65FRftT+5MMQevD5r093voHvCeQPWNlQUuSzh94VVc=";
  buildInputs = [ openssl ];

  OPENSSL_DIR = "${lib.getDev openssl}";
  OPENSSL_LIB_DIR = "${lib.getLib openssl}/lib";

  nativeBuildInputs = [ protobuf ];
  nativeCheckInputs = [ cloud-utils ];
  doCheck = true;

  meta = {
    description = "Separation Context Layer";
    license = lib.licenses.gpl2Only;
    teams = with lib.teams; [ ctrl-os ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
