{ lib, ... }:
let
  payload = builtins.fromJSON (builtins.readFile ./show.json);
  resourcesInModule = type: module:
    builtins.filter (r: r.type == type) module.resources ++
    lib.flatten (map (resourcesInModule type) (module.child_modules or [ ]));
  resourcesByType = type: resourcesInModule type payload.values.root_module;
in
rec {
  resources = resourcesByType "libvirt_domain";
  resourcesByRole = role:
    (builtins.filter (r: lib.strings.hasPrefix role r.values.name) resources);
}
