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
    hash = "sha256-KeUAdZzQPbROD9uM//EM/h1nKlEA0UaVS/03yicMrMA=";
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
    license = lib.licenses.eupl12;
    maintainers = with lib.maintainers; [ messemar ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
