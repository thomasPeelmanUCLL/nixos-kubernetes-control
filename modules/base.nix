{ pkgs, ... }:
{
  # Import alongside the existing hardware configuration.
  # Keep the installed bootloader, NetworkManager and user configuration.
  environment.systemPackages = with pkgs; [ git curl vim ];

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PermitRootLogin = "no";
      AllowUsers = [ "tom" ];
      # Bootstrap only: replace password access with an authorized public key.
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = false;
      X11Forwarding = false;
    };
  };
}
