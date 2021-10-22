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
  #
  # This has probably been solved by
  # https://github.com/zhaofengli/colmena/commit/7b69946d98faa03298f2e181016cb928f1fab4c2
  # TODO: bump Colmena and remove these

  users.users = {
    coredns = { isSystemUser = true; };
    etcd = { isSystemUser = true; };
    kubernetes = { isSystemUser = true; };
  };
}
