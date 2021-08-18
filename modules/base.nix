{
  imports = [ ./boot.nix ./login.nix ];

  # Provision users that will use secrets in advance.
  # As this is imported by boot/image.nix,
  # *all* machines will have *all* of these users set up from the start.
  # The exact security implications of having extra users/groups that will sometimes sit unused
  # are not clear to me at the moment.
  #
  # Avoids permission issues on first deploy.
  # See: https://github.com/zhaofengli/colmena/issues/10

  users.users = {
    etcd = { isSystemUser = true; };
  };
}
