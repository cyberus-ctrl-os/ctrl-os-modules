{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.programs.sclctl;
  sclctl-wrapped =
    pkgs.runCommand "sclctl-wrapped"
      {
        buildInputs = [ pkgs.makeWrapper ];
      }
      ''
        mkdir -p $out/bin
        ln -s ${pkgs.scl}/bin/sclctl $out/bin
        wrapProgram $out/bin/sclctl --set SCLCTL_API_URL ${cfg.url} --set SCLCTL_CA_CERT_FILE ${cfg.mtls.caCertificate} --set SCLCTL_CLIENT_CERT_FILE ${cfg.mtls.cert} --set SCLCTL_CLIENT_KEY_FILE ${cfg.mtls.key}
      '';
in
{
  options.programs.sclctl = {
    enable = lib.mkEnableOption "Enable Separation Context Layer Management command line tool";
    package = lib.mkPackageOption { inherit sclctl-wrapped; } "sclctl-wrapped" { };

    url = lib.mkOption {
      type = lib.types.nonEmptyStr;
      description = "The URL of the SCL API";
      default = "https://localhost:8008";
    };

    mtls = {
      caCertificate = lib.mkOption {
        description = "The CA certificate path for mutual TLS authentication";
        type = lib.types.path;
      };
      cert = lib.mkOption {
        description = "The client mTLS certificate";
        type = lib.types.path;
      };
      key = lib.mkOption {
        description = "The client mTLS key";
        type = lib.types.path;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.mtls != null || cfg.mtls != { };
        message = "sclctl requires mtls certificates to authenticate to the API!";
      }
    ];

    environment = {
      systemPackages = [ cfg.package ];
    };
  };
}
