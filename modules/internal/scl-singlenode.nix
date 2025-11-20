{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.scl-singlenode;
  l3Cfg = cfg.l3NetController;
  l2Cfg = cfg.l2NetApi;
  computeCfg = cfg.computeApi;

  # The available cpu cores of the host system
  # The available cpus are used to allow a static resource allocation per vm
  # This does not necessarily means that the cpus are used exclusively for the
  # VM, but ensures that VMs are not able to overcommit the host resources.
  # The below command takes only CPUs into account that are available to the,
  # Linux scheduler
  hostAvailableCpus = "''$(${pkgs.coreutils}/bin/nproc)";

  # Helper for the grep command
  grep = "${pkgs.gnugrep}/bin/grep";

  # Helper to determine the actual available host main memory.
  # The helper ensures that no overcommitment of memory is possible.
  # Since the virtual machine management application allows the static
  # assignment of memory for a vm only, we must determine the amount of memory,
  # the vmm is able to hand over to vms
  ramMB = "''$((($(${pkgs.coreutils}/bin/cat /proc/meminfo | ${grep} -i memtotal | ${grep} -o '[[:digit:]]*')*75)/102400))";

  sclApiUrl = "https:/127.0.0.1:${toString cfg.api.listenPort}/api/v1";

  secretsPath = "${cfg.dataDir}/certs";
  apiTokenPath = "${secretsPath}/apitoken.secret";
  caCertPath = "${secretsPath}/ca";

  mkService = script: {
    enable = true;
    wantedBy = [ "scl.target" ];
    after = [ "scl-api.service" ];
    requires = [ "scl-api.service" ];
    partOf = [ "scl-api.service" ];
    path = [ cfg.package ];
    inherit environment;
    script = "exec ${script}";
    serviceConfig = {
      Restart = "always";
      Type = "exec";
    };
    startLimitIntervalSec = 10;
    startLimitBurst = 20;
  };

  mkTlsOptions = name: {
    cert = mkOption {
      description = "The TLS certificate";
      type = types.path;
      default = "${secretsPath}/${name}.pem";
      defaultText = ''\${config.services.scl.dataDir}/certs/${name}.pem'';
    };
    key = mkOption {
      description = "The TLS key";
      type = types.path;
      defaultText = ''\${config.services.scl.dataDir}/certs/${name}-key.pem'';
      default = "${secretsPath}/${name}-key.pem";
    };
  };

  # The CA root certificate to generate for TLS Authentication if the easyCerts option is enabled
  csrCAFile = pkgs.writeText "scl-root-ca-csr.json" (
    builtins.toJSON {
      key = {
        algo = "rsa";
        size = 2048;
      };
      names = lib.singleton {
        CN = "scl-CA";
        O = "NixOS";
        OU = "services.scl-singlenode";
        L = "auto-generated";
      };
    }
  );
in
{
  options.services.scl-singlenode = {
    enable = mkEnableOption "Enable the Separation Context Layer management application";

    package = mkPackageOption pkgs "scl" { };

    easyCerts = mkOption {
      description = "Whether to generate TLS and mTLS certificates automatically for the service";
      type = types.bool;
      default = true;
    };

    logLevel = mkOption {
      description = "The log level of the Separation Context Layer management application";
      type = types.enum [
        "DEBUG"
        "ERROR"
        "INFO"
        "OFF"
        "TRACE"
        "WARN"
      ];
      default = "INFO";
    };

    sclctl.tls = mkTlsOptions "sclctl";

    dataDir = mkOption {
      description = "The directory, where the volumes of the virtual machines should be stored on disk";
      type = types.path;
      default = "/var/lib/scl";
    };

    caCertificate = mkOption {
      description = "The CA certificate path";
      type = types.path;
      defaultText = ''\${config.services.scl.dataDir}/certs/scl-ca.pem'';
      default = "${secretsPath}/scl-ca.pem";
    };

    api = {
      listenAddress = mkOption {
        description = ''
          The IPv4 listen Address of the REST API.

          - 0.0.0.0 to allow any connection
        '';
        default = "127.0.0.1";
        type = types.nonEmptyStr;
      };

      listenPort = mkOption {
        description = "The listening port of the REST API.";
        type = types.nonEmptyStr;
        default = "8008";
      };

      tls = mkTlsOptions "scl-api";

      database = {
        url = mkOption {
          description = "The location of the ETCD database";
          default = "http://127.0.0.1:2379";
          type = types.nonEmptyStr;
        };
        mtls = {
          enable = mkEnableOption "Enable mutual TLS for the communication to the database";
        }
        // mkTlsOptions "scl-api-database";
      };
    };

    l2NetApi = {
      listenAddress = mkOption {
        description = "The IPv4 listen Address of the REST API.";
        default = "127.0.0.1";
        type = types.nonEmptyStr;
      };

      listenPort = mkOption {
        description = "The listening port of the REST API.";
        type = types.nonEmptyStr;
        default = "9000";
      };
    };

    scheduler.tls = mkTlsOptions "scheduler-ctrl";

    virtualMachineController.tls = mkTlsOptions "vm-ctrl";

    volumeController.tls = mkTlsOptions "vol-ctrl";

    l2NetController.tls = mkTlsOptions "l2-net-ctrl";

    l3NetController = {
      tls = mkTlsOptions "l3-net-ctrl";

      gateway = mkOption {
        description = "Name of the network interface that should be used as gateway.";
        type = types.nonEmptyStr;
      };

      hostGuestBridgeConfig = {
        name = mkOption {
          description = "Name of the bridge device between the host and the guest network namespace";
          type = types.nonEmptyStr;
          default = "scl-br";
        };

        ipv4 = mkOption {
          description = "IPv4 address of the network bridge between host and guest network namespace";
          type = types.nonEmptyStr;
          default = "192.168.10.1";
        };

        netmask = mkOption {
          description = "Subnet mask of the host guest bridge network";
          type = types.nonEmptyStr;
          default = "255.255.255.0";
        };
      };
    };

    computeApi = {
      listenAddress = mkOption {
        description = "The IPv4 listen Address of the REST API.";
        default = "127.0.0.1";
        type = types.nonEmptyStr;
      };

      listenPort = mkOption {
        description = "The listening port of the REST API.";
        type = types.nonEmptyStr;
        default = "4242";
      };

      maxCpus = mkOption {
        description = ''
          The maximum number of cores that all vms are allowed to use.

          By default, the maximum number of CPUs is determined at runtime using
          the host cpu core count via nproc.
          Overcommitting CPU cores is possible.
        '';
        type = with types; nullOr ints.positive;
        default = null;
      };

      maxMemory = mkOption {
        description = ''
          The maximum amount of memory in megabytes that the virtual machinesd are allowed to use.

          By default, 75 percent of the host memory, determined at runtime is made available to the virtual machines.
          Overcommiting memory is possible, but not recommended.
        '';
        type = with types; nullOr ints.positive;
        default = null;
      };

      cloud-hypervisor = {
        runtimeDir = mkOption {
          description = "Where to store the runtime data of all virtual machines";
          type = types.path;
          default = "/run/scl-compute-api/vms";
        };
        logDir = mkOption {
          description = "Where to store the log files of all virtual machines";
          type = types.path;
          default = "/var/log/scl/compute-api/vms";
        };
        dataDir = mkOption {
          description = "Where to store the persistent data for all virtual machines";
          type = types.path;
          default = "/var/lib/scl/compute-api/vms";
        };
        package = mkPackageOption pkgs "cloud-hypervisor" { };

        firmware = {
          package = mkOption {
            description = "The firmware to use to boot a VM in cloud hypervisor";
            type = types.package;
            default = pkgs.OVMF-cloud-hypervisor.fd;
            defaultText = "pkgs.OVMF-cloud-hypervisor.fd";
          };

          filePath = mkOption {
            type = with types; nullOr nonEmptyStr;
            description = ''
              The relative file path of the firmware binary inside the firmware package
              If the filePath attribute is null, the package itself is interpreted as the firmware binary
            '';
            default =
              {
                aarch64-linux = "FV/CLOUDHV_EFI.fd";
                x86_64-linux = "FV/CLOUDHV.fd";
              }
              ."${pkgs.system}";
            defaultText = "FV/CLOUDHV.fd";
          };
        };
      };
    };

    imageRegistry = {
      enable = mkEnableOption "Enable the simple virtual machine image registry" // {
        default = true;
      };

      dataDir = mkOption {
        description = "Path to store the images, or symlinks to the images";
        type = types.path;
        default = "/var/lib/scl/registry";
      };

      listenAddress = mkOption {
        description = "The IPv4 listen Address of the HTTP Server.";
        default = "127.0.0.1";
        type = types.nonEmptyStr;
      };

      listenPort = mkOption {
        description = "The listening port of the HTTP Server.";
        type = types.port;
        default = 9009;
      };
    };
  };

  config = mkMerge [
    (mkIf cfg.imageRegistry.enable {
      services.static-web-server = {
        enable = true;
        root = cfg.imageRegistry.dataDir;
        listen = "${cfg.imageRegistry.listenAddress}:${builtins.toString cfg.imageRegistry.listenPort}";
      };
      systemd.tmpfiles.settings = {
        "prepare-scl-image-registry-root" = {
          "${cfg.imageRegistry.dataDir}".d = {
            user = "root";
            group = "root";
          };
        };
      };
    })
    (mkIf cfg.easyCerts {
      systemd.tmpfiles.settings = {
        "scl-certificates" = {
          "${secretsPath}".d = {
            group = "cfssl";
            mode = "0775";
          };
        };
      };
      systemd.services.cfssl.preStart = ''
        if [ ! -f "${caCertPath}.pem" ]; then
          ${pkgs.cfssl}/bin/cfssl genkey -initca ${csrCAFile} | ${pkgs.cfssl}/bin/cfssljson -bare ${caCertPath}
        fi
        if [ ! -f "${apiTokenPath}" ]; then
          install -o cfssl -m 400 <(head -c 16 /dev/urandmom | od -An -t x | tr -d ' ') "${apiTokenPath}"
        fi
      '';
      services.cfssl = {
        enable = true;
        address = "127.0.0.1";
        dataDir = secretsPath;
        configFile = toString (
          pkgs.writeText "cfssl-config.json" (
            builtins.toJSON {
              signing = {
                profiles = {
                  default = {
                    usages = [
                      "content commitment"
                      "digital signature"
                      "key encipherment"
                      "client auth"
                      "server auth"
                    ];
                    auth_key = "default";
                    expiry = "720h";
                  };
                };
              };
              auth_keys = {
                default = {
                  type = "standard";
                  key = "file:${apiTokenPath}";
                };
              };
            }
          )
        );
      };
      systemd.services.certmgr.path = [
        pkgs.bash
        pkgs.systemd
      ];
      services.certmgr =
        let
          remote = "http://localhost:${toString config.services.cfssl.port}";
          mkSpec =
            {
              name,
              tlsOptions,
              extraConfig ? { },
            }:
            lib.recursiveUpdate {
              action = ''
                ${pkgs.openssl}/bin/openssl pkcs8 -topk8 -nocrypt -in ${tlsOptions.key}-pkcs1 -out ${tlsOptions.key}
                ${pkgs.systemd}/bin/systemctl try-restart ${name}.service
              '';
              authority = {
                inherit remote;
                profile = "default";
                label = "scl-CA";
                auth_key_file = apiTokenPath;
              };
              certificate.path = tlsOptions.cert;
              private_key.path = "${tlsOptions.key}-pkcs1";
              request = {
                CN = "${name}";
                hosts = [
                  "localhost"
                  "127.0.0.1"
                ];
                key = {
                  algo = "rsa";
                  size = 2048;
                };
                names = lib.singleton {
                  O = "NixOS";
                  OU = "services.${name}";
                  L = "auto-generated";
                };
              };
            } extraConfig;
        in
        {
          enable = true;
          svcManager = "command";
          specs = {
            ca = mkSpec {
              name = "scl-api";
              tlsOptions = cfg.api.tls;
              extraConfig = {
                authority.file.path = cfg.caCertificate;
              };
            };
            scl-local-l2-net-ctrl = mkSpec {
              name = "scl-local-l2-net-ctrl";
              tlsOptions = cfg.l2NetController.tls;
            };
            scl-local-l3-net-ctrl = mkSpec {
              name = "scl-local-l3-net-ctrl";
              tlsOptions = l3Cfg.tls;
            };
            scl-local-vol-ctrl = mkSpec {
              name = "scl-local-vol-ctrl";
              tlsOptions = cfg.volumeController.tls;
            };
            scl-scheduler-ctrl = mkSpec {
              name = "scl-scheduler-ctrl";
              tlsOptions = cfg.scheduler.tls;
            };
            scl-vm-ctrl = mkSpec {
              name = "scl-vm-ctrl";
              tlsOptions = cfg.virtualMachineController.tls;
            };
            sclctl = mkSpec {
              name = "sclctl";
              tlsOptions = cfg.sclctl.tls;
              extraConfig = {
                action = ''
                  ${pkgs.openssl}/bin/openssl pkcs8 -topk8 -nocrypt -in ${cfg.sclctl.tls.key}-pkcs1 -out ${cfg.sclctl.tls.key}
                '';
              };
            };
          };
        };

      programs.sclctl.mtls = {
        inherit (cfg) caCertificate;
        inherit (cfg.sclctl.tls) cert key;
      };
    })
    (mkIf cfg.enable {

      assertions = [
        {
          assertion = config.networking.hostId != null;
          message = ''
            networking.hostId is required for scl-singlenode to operate. Please specify it according to the documentation
          '';
        }
      ];

      programs.sclctl.url = sclApiUrl;

      services.etcd = {
        enable = true;
        listenClientUrls = [ cfg.api.database.url ];
        clientCertAuth = cfg.api.database.mtls.enable;
      };

      systemd.targets.scl = {
        enable = true;
        bindsTo = [ "multi-user.target" ];
        wantedBy = [ "multi-user.target" ];
        requires = [ "network-online.target" ] ++ lib.optional (cfg.easyCerts) "certmgr.service";
        after = [ "network-online.target" ] ++ lib.optional (cfg.easyCerts) "certmgr.service";
      };

      systemd.services = {
        scl-api = {
          enable = true;
          wantedBy = [ "scl.target" ];
          path = [ cfg.package ];
          preStart = ''
            while [[ ! ( -f "${cfg.caCertificate}" && ${
              lib.concatStringsSep " && " (
                builtins.map (tls: ''-f "${tls.key}" && -f "${tls.cert}" '') [
                  cfg.api.tls
                  cfg.sclctl.tls
                  cfg.scheduler.tls
                  cfg.virtualMachineController.tls
                  cfg.volumeController.tls
                  cfg.l2NetController.tls
                  cfg.l3NetController.tls
                ]
                ++ lib.optional (cfg.api.database.mtls.enable) cfg.api.database.mtls
              )
            } ) ]]; do
              echo "waiting for certificates"
              sleep 1
            done
          '';
          script = "exec scl-api";
          serviceConfig = {
            Restart = "always";
            Type = "exec";
          };
          after = [
            "network-online.target"
            "etcd.service"
          ]
          ++ lib.optional (cfg.easyCerts) "certmgr.service";
          requires = [
            "network-online.target"
            "etcd.service"
          ]
          ++ lib.optional (cfg.easyCerts) "certmgr.service";
          environment = {
            SCL_API_ADDRESS = cfg.api.listenAddress;
            SCL_API_PORT = cfg.api.listenPort;
            SCL_API_DB_URL = cfg.api.database.url;
            SCL_API_LOG_LEVEL = cfg.logLevel;
            SCL_API_CA_CERT = cfg.caCertificate;
            SCL_API_TLS = ''
              {
                certs = ${cfg.api.tls.cert},
                key = ${cfg.api.tls.key},
                mutual = {
                  mandatory = true,
                  ca_certs = ${cfg.caCertificate}
                }
              }'';
          }
          // lib.optionalAttrs (cfg.api.database.mtls.enable) {
            SCL_API_DB_MTLS = ''
              {
                cert = ${cfg.api.database.mtls.cert},
                key = ${cfg.api.database.mtls.key},
              }
            '';
          };
        };

        scl-node-l2-net-api = mkService "node-l2-net-api" // {
          environment = {
            NODE_L2_NET_API_ADDRESS = l2Cfg.listenAddress;
            NODE_L2_NET_API_PORT = l2Cfg.listenPort;
            NODE_L2_NET_API_LOG_LEVEL = cfg.logLevel;
          };
          path = with pkgs; [
            iproute2
            cfg.package
          ];
        };

        scl-compute-api = mkService "compute-api" // {
          after = [
            "scl-api.service"
            "scl-node-l2-net-api.service"
          ];
          environment = {
            SCLCTL_API_URL = sclApiUrl;
            SCLCTL_CA_CERT_FILE = cfg.caCertificate;
            SCLCTL_CLIENT_CERT_FILE = cfg.sclctl.tls.cert;
            SCLCTL_CLIENT_KEY_FILE = cfg.sclctl.tls.key;
            COMPUTE_API_ADDRESS = computeCfg.listenAddress;
            COMPUTE_API_PORT = computeCfg.listenPort;
            COMPUTE_API_LOG_LEVEL = cfg.logLevel;
            COMPUTE_API_CLOUD_HYPERVISOR__RUNTIME_DIR = computeCfg.cloud-hypervisor.runtimeDir;
            COMPUTE_API_CLOUD_HYPERVISOR__LOG_DIR = computeCfg.cloud-hypervisor.logDir;
            COMPUTE_API_CLOUD_HYPERVISOR__DATA_DIR = computeCfg.cloud-hypervisor.dataDir;
            COMPUTE_API_CLOUD_HYPERVISOR__KERNEL_FIRMWARE =
              "${computeCfg.cloud-hypervisor.firmware.package}"
              + lib.optionalString (
                computeCfg.cloud-hypervisor.firmware.filePath != null
              ) "/${computeCfg.cloud-hypervisor.firmware.filePath}";
          };
          path = [
            cfg.package
            computeCfg.cloud-hypervisor.package
            pkgs.cloud-utils
            pkgs.qemu-utils
            pkgs.iproute2
            pkgs.coreutils
          ];
          postStart = ''
            if ! sclctl node show local-${config.networking.hostId}
            then
              cpus=${toString (if computeCfg.maxCpus != null then computeCfg.maxCpus else hostAvailableCpus)}
              ram=${toString (if computeCfg.maxMemory != null then computeCfg.maxMemory else ramMB)}
              sclctl node create local-${config.networking.hostId} \
                --nic-api http://localhost:${toString l2Cfg.listenPort} \
                --node-api http://localhost:${toString computeCfg.listenPort} \
                --vcpu $cpus \
                --ram $ram
            fi
          '';
        };

        scl-local-l2-net-ctrl = mkService "scl-local-l2-net-ctrl" // {
          environment = {
            SCL_LOCAL_L2_NET_CTRL_API_URL = sclApiUrl;
            SCL_LOCAL_L2_NET_CTRL_LOG_LEVEL = cfg.logLevel;
            SCL_LOCAL_L2_NET_CTRL_CA_CERT_FILE = cfg.caCertificate;
            SCL_LOCAL_L2_NET_CTRL_CLIENT_CERT_FILE = cfg.l2NetController.tls.cert;
            SCL_LOCAL_L2_NET_CTRL_CLIENT_KEY_FILE = cfg.l2NetController.tls.key;
          };
          after = [
            "scl-api.service"
            "scl-node-l2-net-api.service"
            "scl-compute-api.service"
          ];
          requires = [
            "scl-api.service"
            "scl-node-l2-net-api.service"
            "scl-compute-api.service"
          ];

        };

        scl-local-l3-net-ctrl = mkService "scl-local-l3-net-ctrl" // {
          environment = {
            SCL_LOCAL_L3_NET_CTRL_API_URL = sclApiUrl;
            SCL_LOCAL_L3_NET_CTRL_LOG_LEVEL = cfg.logLevel;
            SCL_LOCAL_L3_NET_CTRL_GATEWAY_NAME = l3Cfg.gateway;
            SCL_LOCAL_L3_NET_CTRL_SCL_BRIDGE_NAME = l3Cfg.hostGuestBridgeConfig.name;
            SCL_LOCAL_L3_NET_CTRL_SCL_BRIDGE_IP = l3Cfg.hostGuestBridgeConfig.ipv4;
            SCL_LOCAL_L3_NET_CTRL_SCL_BRIDGE_NETMASK = l3Cfg.hostGuestBridgeConfig.netmask;
            SCL_LOCAL_L3_NET_CTRL_CA_CERT_FILE = cfg.caCertificate;
            SCL_LOCAL_L3_NET_CTRL_CLIENT_CERT_FILE = l3Cfg.tls.cert;
            SCL_LOCAL_L3_NET_CTRL_CLIENT_KEY_FILE = l3Cfg.tls.key;
          };
          path = with pkgs; [
            cfg.package
            iproute2
            iptables
          ];
        };

        scl-local-vol-ctrl = mkService "scl-local-vol-ctrl" // {
          environment = {
            SCL_LOCAL_VOL_CTRL_API_URL = sclApiUrl;
            SCL_LOCAL_VOL_CTRL_LOG_LEVEL = cfg.logLevel;
            SCL_LOCAL_VOL_CTRL_VOLUME_ROOT_DIRECTORY = cfg.dataDir;
            SCL_LOCAL_VOL_CTRL_CA_CERT_FILE = cfg.caCertificate;
            SCL_LOCAL_VOL_CTRL_CLIENT_CERT_FILE = cfg.volumeController.tls.cert;
            SCL_LOCAL_VOL_CTRL_CLIENT_KEY_FILE = cfg.volumeController.tls.key;
          };

          path = with pkgs; [
            qemu-utils
            util-linux
            cfg.package
          ];
        };

        scl-scheduler-ctrl = mkService "scl-scheduler-ctrl" // {
          environment = {
            SCL_SCHEDULER_CTRL_API_URL = sclApiUrl;
            SCL_SCHEDULER_CTRL_LOG_LEVEL = cfg.logLevel;
            SCL_SCHEDULER_CTRL_CA_CERT_FILE = cfg.caCertificate;
            SCL_SCHEDULER_CTRL_CLIENT_CERT_FILE = cfg.scheduler.tls.cert;
            SCL_SCHEDULER_CTRL_CLIENT_KEY_FILE = cfg.scheduler.tls.key;
          };
        };

        scl-vm-ctrl = mkService "scl-vm-ctrl" // {
          environment = {
            SCL_VM_CTRL_API_URL = sclApiUrl;
            SCL_VM_CTRL_LOG_LEVEL = cfg.logLevel;
            SCL_VM_CTRL_CA_CERT_FILE = cfg.caCertificate;
            SCL_VM_CTRL_CLIENT_CERT_FILE = cfg.virtualMachineController.tls.cert;
            SCL_VM_CTRL_CLIENT_KEY_FILE = cfg.virtualMachineController.tls.key;
          };
          path = [
            cfg.package
            pkgs.cloud-utils
          ];
        };
      };
    })
  ];
}
