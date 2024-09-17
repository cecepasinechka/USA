{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = github:NixOS/nixpkgs;
  };
  outputs =
    { self
    , nixpkgs
    , nixpkgs-unstable
    }: {
      formatter.aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixpkgs-fmt;
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;

      nixosModules.vm =
        { pkgs, ... }:
        {
          system.stateVersion = "24.05";

          networking.useDHCP = false;
          networking.interfaces.eth0.useDHCP = true;

          services.getty.autologinUser = "vm";
          users.users.vm.isNormalUser = true;

          users.users.vm.extraGroups = [ "wheel" ];
          security.sudo.wheelNeedsPassword = false;

          networking.firewall.allowedTCPPorts = [ 80 ];
        };

      nixModules.virtualisation =
        { pkgs, ... }: {
          virtualisation.vmVariant.virtualisation.graphics = false;
          virtualisation.vmVariant.virtualisation.forwardPorts = [
            { from = "host"; host.port = 8888; guest.port = 80; }
          ];
        };

      nixosModules.wordpress =
        { pkgs, ... }:
        let
          hever = pkgs.stdenv.mkDerivation rec {
            name = "hever";
            version = "1.5.30";
            src = pkgs.fetchzip {
              url = "https://public-api.wordpress.com/rest/v1/themes/download/hever.zip";
              hash = "sha256-3Ca2HFRuqyf7qCuEsTyOnOdqW+OI7NToY9EJpV8WIow=";
            };
            installPhase = "mkdir -p $out; cp -R * $out/";
          };
          dyad = pkgs.stdenv.mkDerivation rec {
            name = "dyad";
            version = "1.0.10";
            src = pkgs.fetchzip {
              url = "https://downloads.wordpress.org/theme/dyad.${version}.zip";
              hash = "sha256-fgMeVUfwyu/wtSsWy1nQvh/Q556Psm6DTGGlYxeV3uk=";
            };
            installPhase = "mkdir -p $out; cp -R * $out/";
          };
          varia-wpcom = pkgs.stdenv.mkDerivation rec {
            name = "varia-wpcom";
            version = "1.6.33";
            src = pkgs.fetchzip {
              url = "https://public-api.wordpress.com/rest/v1/themes/download/varia.zip";
              hash = "sha256-Yw6KmldMK/gG3wR6rFZxDA+x0PVlha0yLchoTz97b0Q=";
            };
            installPhase = "mkdir -p $out; cp -R * $out/";
          };
          pkgs-unstable = import nixpkgs-unstable {
            system = "x86_64-linux";
          };
        in
        {
          services.wordpress = {
            webserver = "nginx";

            sites."localhost" = {
              settings = { };
              package = pkgs-unstable.wordpress;

              themes = {
                inherit varia-wpcom dyad hever;
              };
            };

          };
        };
      nixosConfigurations.darwin.vm = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          self.nixosModules.vm
          {
            virtualisation.vmVariant.virtualisation.host.pkgs = nixpkgs.legacyPackages.aarch64-darwin;
          }
          self.nixModules.virtualisation

          self.nixosModules.wordpress
        ];
      };

      nixosConfigurations.vm = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          self.nixosModules.vm
          self.nixModules.virtualisation

          self.nixosModules.wordpress
        ];
      };
    };
}
