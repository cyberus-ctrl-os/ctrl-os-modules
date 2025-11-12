{ config, lib, ... }:
let
  cfg = config.ctrl-os.developer;
in
{
  options = {
    ctrl-os.developer = {
      enable = lib.mkEnableOption "common CTRL-OS developer settings";
    };
  };

  config = lib.mkIf cfg.enable {
    nix = {
      # We re-use the suggested settings from the flake. If there is a better way to do this, please suggest it. :-)
      settings = {
        extra-trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        ];

        extra-substituters = [
          "https://cache.ctrl-os.com/"
        ];

        # While some developers prefer not to use flakes for their
        # projects, it is convenient to have them enabled to
        # copy'n'paste documentation snippets.
        experimental-features = [ "nix-command" "flakes" ];
      };
    };
  };
}
