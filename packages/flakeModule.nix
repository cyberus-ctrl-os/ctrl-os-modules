{ withSystem, inputs, self, ... }:
{ }
//
  inputs.nixpkgs.lib.optionalAttrs
    (inputs.nixpkgs.lib.versionAtLeast inputs.nixpkgs.lib.version "25.11")
    {
      flake.overlays = rec {
        default = vms;
        vms =
          _: prev:
          withSystem prev.stdenv.hostPlatform.system (
            { config, ... }:
            {
              scl = config.packages.scl;
              OVMF-cloud-hypervisor = config.packages.OVMF-cloud-hypervisor;
            }
          );
      };

      perSystem =
        { pkgs, system, ... }:
        {
          packages = (import ./default.nix { inherit pkgs; }) // {
            jetsonOrinNanoInstaller =
              (inputs.nixpkgs.lib.nixosSystem {
                modules = [
                  (
                    { config, pkgs, lib, modulesPath, ... }:
                    {
                      imports = [
                        "${modulesPath}/profiles/installation-device.nix"
                        "${modulesPath}/image/repart.nix"

                        self.nixosModules.hardware
                        self.nixosModules.developer
                      ];
                      
                      nix.settings = {
                        trusted-users = [ "root" "julian" ];
                      };

                      users.users.julian = {
                        description = "Julian Stecklina";
                        isNormalUser = true;
                        extraGroups = [ "wheel" "video" "kvm" "networkmanager" "dialout" "libvirtd" "docker" "vboxusers" ];
                        createHome = true;

                        openssh.authorizedKeys.keys = [
                          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIErZm6k0S7NahikKEbTQlrOrsLKgr9X+iNoUsGeqDV0F julian@canaan.xn--pl-wia.net"
                          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEdmNCi+XT6V9hrvJMHbnQfGY23zcHfnxjqaq4ZG3k27 julian@second-temple"
                          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICeIiTyh7jJD9x8N64kgUGDgeo3F96i5Av3tHvwePHq5 julian@babylon"
                        ];

                        hashedPassword = "$6$d4Q85PrE$m/mrZqoe6R4oi.2NHoB6gJicQr85yKtnmZBXUeyap7KPGKCp9SLqfPOprY12cJtjCcM3bsXTUVzS3O6n8VNTx0";
                      };

                      services.openssh.enable = true;


                      # The option names are weird.
                      system.installer.channel.enable = false;
                      installer.cloneConfig = false;

                      ctrl-os.developer.enable = true;
                      ctrl-os.hardware.platform = "nvidia-jetson-orin-nano";

                      # Cross-compiling was broken, but we also don't need it.
                      networking.modemmanager.enable = false;

                      # Networkmanager still pulls in modemmanager. Why?
                      networking.networkmanager.enable = lib.mkForce false;

                      nixpkgs.buildPlatform = system;
                      system.stateVersion = lib.trivial.release;

                      boot.loader.grub.enable = false;
                      boot.loader.systemd-boot.enable = true;

                      boot.growPartition = true;

                      fileSystems = {
                        "/" = {
                          device = "/dev/disk/by-partlabel/instroot";
                          fsType = "ext4";
                          autoResize = true;
                        };

                        "/boot" = {
                          device = "/dev/disk/by-partlabel/instboot";
                          fsType = "vfat";
                        };
                      };

                      image.repart = let
                        efiArch = pkgs.stdenv.hostPlatform.efiArch;
                      in {
                        name = "image";
                        partitions = {

                          "01-esp" = {
                            contents = {
                              "/EFI/BOOT/BOOT${lib.toUpper efiArch}.EFI".source =
                                "${pkgs.systemd}/lib/systemd/boot/efi/systemd-boot${efiArch}.efi";

                              "/EFI/Linux/${config.system.boot.loader.ukiFile}".source =
                                "${config.system.build.uki}/${config.system.boot.loader.ukiFile}";
                            };
                            repartConfig = {
                              Type = "esp";
                              Format = "vfat";
                              SizeMinBytes = "1G";
                              Label = "instboot";
                            };
                          };

                          "02-swap" = {
                            repartConfig = {
                              Type = "swap";
                              Format = "swap";
                              SizeMinBytes = "2G";
                            };
                          };

                          # Needs to be last (ordered by name) to allow autoResize to work.
                          "03-root" = {
                            storePaths = [ config.system.build.toplevel ];
                            nixStorePrefix = "/nix/store";
                            repartConfig = {
                              Type = "root";
                              Label = "instroot";
                              Format = "ext4";

                              SizeMinBytes = "4G";
                            };
                          };
                        };
                      };
                    }
                  )
                ];
              }).config.system.build.image;
          };
        };
    }
