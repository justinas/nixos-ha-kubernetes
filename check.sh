#!/usr/bin/env bash
set -ex

etcd1_ip=$(jq -r '.values.root_module.child_modules[] | .resources[] | select(.values.name == "etcd1").values.network_interface[0].addresses[0]' show.json)

etcdctl --endpoints "https://$etcd1_ip:2379" \
    --ca-file ./certs/generated/etcd/ca.pem \
    --cert-file ./certs/generated/etcd/peer.pem \
    --key-file ./certs/generated/etcd/peer-key.pem \
    member list | grep -q isLeader=true

k --request-timeout 1 cluster-info

echo "Success."
