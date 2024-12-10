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
            version = "1.6.35";
            src = pkgs.fetchzip {
              url = "https://public-api.wordpress.com/rest/v1/themes/download/varia.zip";
              hash = "sha256-V4YsrTirJSNL9v6EWs3MdI9SYPCsOMAkOzN6/kmjW4k=";
            };
            installPhase = "mkdir -p $out; cp -R * $out/";
          };

          ml-slider = pkgs.stdenv.mkDerivation rec {
            name = "ml-slider";
            version = "3.91.0";
            src = pkgs.fetchzip {
              url = "https://downloads.wordpress.org/plugin/ml-slider.3.91.0.zip";
              hash = "sha256-CUqRBED+zis5XX2EE/LI2QxGOTWdo6q057B4Wd+a100=";
            };
            installPhase = "mkdir -p $out; cp -R * $out/";
          };

          site-kit = pkgs.stdenv.mkDerivation rec {
            name = "site-kit";
            version = "1.141.0";
            src = pkgs.fetchzip {
              url = "https://downloads.wordpress.org/plugin/google-site-kit.1.141.0.zip";
              hash = "sha256-gUM171SPBH2eT/Oj5BHqc4+w69HqLDStNnYzhKVUYys=";
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
              extraConfig = ''
                if( strpos( $_SERVER['HTTP_X_FORWARDED_PROTO'], 'https') !== false ) {
                  $_SERVER['HTTPS'] = 'on';
                }

                // https://developer.wordpress.org/advanced-administration/before-install/development/#two-wordpresses-one-database
                define('WP_HOME',  "https://{$_SERVER['HTTP_HOST']}");
                define('WP_SITEURL', "https://{$_SERVER['HTTP_HOST']}");
              '';

              themes = {
                inherit varia-wpcom dyad hever;
              };

              plugins = {
                inherit ml-slider site-kit;
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
