#!/usr/bin/env bash
set -e

etcd1_ip=$(jq -r '.values.root_module.child_modules[] | .resources[] | select(.values.name == "etcd1").values.network_interface[0].addresses[0]' show.json)

etcdctl --endpoints "https://$etcd1_ip:2379" \
    --ca-file ./certs/generated/etcd/ca.pem \
    --cert-file ./certs/generated/etcd/peer.pem \
    --key-file ./certs/generated/etcd/peer-key.pem \
    member list \
    | tee /dev/stderr | grep -q isLeader=true

k --request-timeout 1 cluster-info

k run --rm --attach --restart Never \
    --image busybox \
    busybox \
    --command id \
    | tee /dev/stderr | grep -q "uid=0(root) gid=0(root) groups=10(wheel)"

k run --rm --attach --restart Never \
    --image busybox \
    busybox \
    --command nslookup kubernetes \
    | tee /dev/stderr | grep -q "Address: 10.32.0.1"

echo "Success."
