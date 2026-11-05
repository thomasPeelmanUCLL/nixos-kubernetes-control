{ pkgs, ... }:
{
  # Import alongside the existing hardware configuration.
  # Keep the installed bootloader, NetworkManager and user configuration.
  environment.systemPackages = with pkgs; [ git curl vim ];

  users.users.tom.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKwIqtxiBKnQ5Vz8UVnA9go4eF2++FzX3Upnm/p+EitH eddsa-key-20261031"
  ];

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PermitRootLogin = "no";
      AllowUsers = [ "tom" ];
      PubkeyAuthentication = true;
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      X11Forwarding = false;
    };
  };
}
