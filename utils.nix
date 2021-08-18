{
  nodeIP = r:
    let interface = (builtins.head r.values.network_interface);
    in (builtins.head interface.addresses);
}
