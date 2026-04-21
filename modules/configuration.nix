{
  modulesPath,
  inputs,
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    "${modulesPath}/profiles/minimal.nix"
    inputs.comin.nixosModules.comin
  ];

  disabledModules = [
    "profiles/base.nix"
  ];

  boot = {
    supportedFilesystems = lib.mkForce {
      ext4 = true;
      vfat = true;
    };
  };

  nix = {
    # Disable registry to avoid pulling nixpkgs source into closure (~450 MB)
    registry = lib.mkForce {};

    settings = {
      experimental-features = ["nix-command" "flakes"];
      auto-optimise-store = true;
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  networking = {
    # Hostname is set by hardware module or can be overridden
    hostName = lib.mkDefault "nixos-embedded";
    useNetworkd = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22 # SSH
      ];
      allowedUDPPorts = [
        5353 # mDNS
      ];
    };
  };

  systemd.network = {
    enable = true;
    networks."10-ethernet" = {
      matchConfig.Type = "ether";
      networkConfig = {
        DHCP = "yes";
        IPv6AcceptRA = true;
      };
      dhcpV4Config.RouteMetric = 100;
    };
  };

  fonts.fontconfig.enable = false;

  services = {
    avahi = {
      enable = true;
      nssmdns4 = true;
      publish = {
        enable = true;
        addresses = true;
      };
    };

    openssh = {
      enable = true;
      hostKeys = [
        {
          path = "/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
      ];
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };

    comin = {
      enable = true;
      package = inputs.comin.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
        git = pkgs.gitMinimal;
      };
      remotes = [
        {
          name = "origin";
          url = "https://github.com/jonathan-chouinard/embedded-nixos.git";
          branches.main.name = "main";
        }
      ];
    };
  };

  time.timeZone = "UTC";

  users.users = {
    root = {
      initialPassword = "root";
    };

    admin = {
      uid = 1000;
      isNormalUser = true;
      initialPassword = "admin";
    };
  };

  security.sudo.extraRules = [
    {
      # TODO: Restrict to specific commands for production
      users = ["admin"];
      commands = [
        {
          command = "ALL";
          options = ["SETENV"];
        }
      ];
    }
  ];

  # Provisioning SSH setup
  # Creates .ssh directory and copies provisioning key on first boot.
  # The key should be replaced during provisioning with a unique per-device key.
  system.activationScripts.sshSetup = let
    user = config.users.users.admin.name;
    group = config.users.users.admin.group;
  in
    lib.stringAfter ["users"] ''
      mkdir -p /home/${user}/.ssh
      chmod 700 /home/${user}/.ssh
      chown ${user}:${group} /home/${user}/.ssh

      if [ ! -f /home/${user}/.ssh/authorized_keys ]; then
        cp ${../secrets/id_ed25519.pub} /home/${user}/.ssh/authorized_keys
        chmod 600 /home/${user}/.ssh/authorized_keys
        chown ${user}:${group} /home/${user}/.ssh/authorized_keys
      fi
    '';

  # Disable tools not needed for embedded device (comin handles updates)
  system.tools.nixos-rebuild.enable = false;

  environment.systemPackages = with pkgs; [
  ];

  system.stateVersion = "25.11";
}
