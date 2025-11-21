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
      settings = {
        extra-trusted-public-keys = [
          "ctrl-os:baPzGxj33zp/P+GAIJXsr8ss9Law+qEEFViX1+flbv8="
        ];

        extra-substituters = [
          "https://cache.ctrl-os.com/"
        ];

        # While some developers prefer not to use flakes for their
        # projects, it is convenient to have them enabled to
        # copy'n'paste documentation snippets.
        experimental-features = [
          "nix-command"
          "flakes"
        ];
      };
    };
  };
}
