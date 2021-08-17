# Allow yourself to SSH to the machines using your public key
let
  # read the first file that exists
  # filenames: list of paths
  readFirst = filenames: builtins.readFile
    (builtins.head (builtins.filter builtins.pathExists filenames));

  sshKey = readFirst [ ~/.ssh/id_ed25519.pub ~/.ssh/id_rsa.pub ];
in
{ config, ... }:
{
  networking.firewall.allowedTCPPorts = config.services.openssh.ports;
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [ sshKey ];
}
