
# Nix Flake for WordPress Setup on https://feriusa.um.si

This `flake.nix` is configured to set up a WordPress site for the domain [https://feriusa.um.si](https://feriusa.um.si), which hosts the webpage for the 2025 USA excursion of FERI UM students. The configuration provides a virtualized environment for the WordPress installation with themes pre-loaded and networking setup for easy access and management.

## Key Features
- **WordPress Installation**: A WordPress instance is set up using `nginx` as the web server. It includes several themes (Hever, Dyad, Varia) fetched directly from official sources.
- **Domain Configuration**: The setup is designed to handle the domain `https://feriusa.um.si` with proper HTTPS forwarding configuration.
- **Virtualization**: The configuration includes support for virtual machines, ensuring the WordPress instance runs in a controlled environment with necessary ports forwarded.
- **DHCP Networking**: Network settings are configured to use DHCP for the virtual machine.
- **Sudo Access**: The default `vm` user has passwordless `sudo` access for administrative tasks.
- **Firewall**: Port `80` (HTTP) is open for web traffic.

## Themes
The following WordPress themes are pre-installed:
1. **Hever** (version 1.5.30)
2. **Dyad** (version 1.0.10)
3. **Varia** (version 1.6.33)

## How to Use
- This flake is designed for both **x86_64-linux** and **ARM64 macOS** platforms.
- It configures a WordPress instance to run on port `80`, with the virtual machine forwarding this to port `8888` on the host.

## Related Content
The following content was found useful:
- [NixOS VM on macOS](https://www.tweag.io/blog/2023-02-09-nixos-vm-on-macos/)
- [Nixpkgs Manual: Darwin Builder](https://nixos.org/manual/nixpkgs/unstable/#sec-darwin-builder)
- [Nix WordPress module](https://github.com/NixOS/nixpkgs/blob/nixos-24.05/nixos/modules/services/web-apps/wordpress.nix)
- [WordPress Reverse Proxy and HTTPS](https://developer.wordpress.org/advanced-administration/security/https/#using-a-reverse-proxy)
