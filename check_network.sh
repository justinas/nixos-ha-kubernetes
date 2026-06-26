#!/usr/bin/env bash

set -e

cleanup() {
    k delete pod network-multitool
    k delete svc network-multitool
}

trap cleanup EXIT

k run --image wbitt/network-multitool -l app=network-multitool --port 80 network-multitool
k expose --type=NodePort pod network-multitool

worker_name=$(k get pod network-multitool -o "jsonpath={.spec.nodeName}")

other_worker_ip=$(jq -r "$(cat <<EOF
.values.root_module.child_modules[] | .resources[] |
select(.type == "libvirt_domain") |
select(.values.name | startswith("worker")) |
select(.values.name != "$worker_name") |
.values.network_interface[0].addresses[0]
EOF
)" show.json)

node_port=$(k get svc network-multitool -o "jsonpath={.spec.ports[0].nodePort}")

echo Will query: "$other_worker_ip:$node_port"
curl --retry 5 --retry-connrefused --fail "$other_worker_ip:$node_port"
echo Success.
