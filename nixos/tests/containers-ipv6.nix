# Test for NixOS' container support.

let
  hostIp = "fc00::2";
  localIp = "fc00::1";
in

import ./make-test.nix ({ pkgs, ...} : {
  name = "containers-ipv6";
  meta = with pkgs.stdenv.lib.maintainers; {
    maintainers = [ aristid aszlig eelco kampfschlaefer ];
  };

  machine =
    { pkgs, ... }:
    { imports = [ ../modules/installer/cd-dvd/channel.nix ];
      virtualisation.writableStore = true;
      virtualisation.memorySize = 768;

      containers.webserver =
        { privateNetwork = true;
          hostAddress6 = hostIp;
          localAddress6 = localIp;
          config =
            { services.httpd.enable = true;
              services.httpd.adminAddr = "foo@example.org";
              networking.firewall.allowedTCPPorts = [ 80 ];
            };
        };

      virtualisation.pathsInNixDB = [ pkgs.stdenv ];
    };

  testScript =
    ''
      $machine->waitForUnit("default.target");
      $machine->succeed("nixos-container list") =~ /webserver/ or die;

      # Start the webserver container.
      $machine->succeed("nixos-container start webserver");

      # wait two seconds for the container to start and the network to be up
      sleep 2;

      # Since "start" returns after the container has reached
      # multi-user.target, we should now be able to access it.
      my $ip = "${localIp}";
      chomp $ip;
      $machine->succeed("ping -n -c 1 $ip");
      $machine->succeed("curl --fail http://[$ip]/ > /dev/null");

      # Stop the container.
      $machine->succeed("nixos-container stop webserver");
      $machine->fail("curl --fail --connect-timeout 2 http://[$ip]/ > /dev/null");

      # Destroying a declarative container should fail.
      $machine->fail("nixos-container destroy webserver");
    '';

})
