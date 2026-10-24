# airplay.nix
{ config, lib, pkgs, ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      shairport-sync = prev.shairport-sync.override { enableAirplay2 = true; };
    })
  ];

  services.shairport-sync = {
    enable = true;
    arguments = "-v -a \"Name of Stereo\" -o alsa -- -d hw:TAS5756M";
  };

  systemd.services.nqptp = {
    description = "Not Quite PTP (AirPlay 2 timing)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.nqptp}/bin/nqptp";
      Restart = "on-failure";
      AmbientCapabilities = "CAP_NET_BIND_SERVICE";
      DynamicUser = true;
    };
  };

  services.avahi = {
    enable = true;
    publish.enable = true;
    publish.userServices = true;
  };

  networking.firewall = {
    trustedInterfaces = [ "end0" ];
    allowedUDPPorts = [ 5353 ];
  };
}
