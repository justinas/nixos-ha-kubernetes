# Toy highly-available Kubernetes cluster on NixOS

<!-- vim-markdown-toc GFM -->

* [About](#about)
    * [Motivation](#motivation)
    * [Architecture](#architecture)
    * [Goals](#goals)
    * [Non-goals](#non-goals)
* [Trying it out](#trying-it-out)
    * [Prerequisites](#prerequisites)
    * [Running](#running)
    * [Verifying](#verifying)
    * [Modifying](#modifying)
    * [Destroying](#destroying)
    * [Tips and tricks](#tips-and-tricks)
* [Contributing](#contributing)
* [Acknowledgements](#acknowledgements)

<!-- vim-markdown-toc -->

## About

A recipe for a cluster of virtual machines managed by [Terraform](https://www.terraform.io/),
running a highly-available Kubernetes cluster,
deployed on NixOS using [Colmena](https://github.com/zhaofengli/colmena).

### Motivation

NixOS provides a Kubernetes module, which is capable of running a `master` or `worker` node.
The module even provides basic PKI, making running simple clusters easy.
However, HA support is limited (see, for example,
[this comment](https://github.com/NixOS/nixpkgs/blob/acab4d1d4dff1e1bbe95af639fdc6294363cce66/nixos/modules/services/cluster/kubernetes/pki.nix)
and an [empty section](https://nixos.wiki/wiki/Kubernetes#N_Masters_.28HA.29)
for "N masters" in NixOS wiki).

This project serves as an example of using the NixOS Kubernetes module in an advanced way,
setting up a cluster that is highly-available on all levels.

### Architecture

External etcd topology,
[as described by Kubernetes docs](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/ha-topology/#external-etcd-topology),
is implemented.
The cluster consists of:
* 3 `etcd` nodes
* 3 `controlplane` nodes, running
  `kube-apiserver`, `kube-controller-manager`, and `kube-scheduler`.
* 2 `worker` nodes, running `kubelet`, `kube-proxy`,
  `coredns`, and a CNI network (currently `flannel`).
* 2 `loadbalancer`, running `keepalived` and `haproxy` which proxies to the Kubernetes API.

### Goals
* All infrastructure declaratively managed by Terraform and Nix (Colmena).
  Zero `kubectl apply -f foo.yaml` invocations required to get a workable cluster.
* All the infrastructure-level services run directly on NixOS / systemd.
  Running `k get pods -A` after the cluster is spun up lists zero pods.
* Functionality. The cluster should be able to run basic real-life deployments,
  although 100% parity with high-profile Kubernetes distributions is unlikely to be reached.
* High-availability.
  A failure of a single service (of any kind) or a single machine (of any role)
  shall not leave the cluster in a non-functional state.

### Non-goals
* Production-readiness. I am not an expert in any of: Nix, Terraform, Kubernetes, HA, etc.
* Perfect security (see the above point).
  Some basic measures are taken: NixOS firewall is left turned on
  (although some overly permissive rules may be in place),
  Kubernetes uses ABAC and RBAC,
  and TLS auth is used between the services.

## Trying it out

### Prerequisites

* Nix (only tested on NixOS, might work on other Linux distros).
* Libvirtd running. For NixOS, put this in your config:
  ```nix
  {
    virtualisation.libvirtd.enable = true;
    users.users."yourname".extraGroups = [ "libvirtd" ];
  }
  ```
* At least 6 GB of available RAM.
* At least 15 GB of available disk space.
* `10.240.0.0/24` IPv4 subnet available (as in, not used for your home network or similar).
  This is used by the "physical" network of the VMs.

### Running

```console
$ nix-shell
$ make-boot-image # Build the base NixOS image to boot VMs from
$ ter apply       # Create the virtual machines
$ make-certs      # Generate TLS certificates for Kubernetes, etcd, and other daemons.
$ colmena apply   # Deploy to your cluster
```

Most of the steps can take several minutes each when running for the first time.

### Verifying

```console
$ ./check.sh                # Prints out diagnostic information about the cluster and tries to run a simple pod.
$ k run --image nginx nginx # Run a simple pod. `k` is an alias of `kubectl` that uses the generated admin credentials.
```

### Modifying

The number of servers of each role can be changed by editing `terraform.tfvars`
and issuing the following commands afterwards:

```console
$ ter apply     # Spin up or spin down machines
$ make-certs    # Regenerate the certs, as they are tied to machine IPs/hostnames
$ colmena apply # Redeploy
```

### Destroying

```console
$ ter destroy   # Destroy the virtual machines
$ rm boot/image # Destroy the base image
```

### Tips and tricks

* After creating and destroying the cluster many times, your `.ssh/known_hosts`
  will get polluted with many entries with the virtual machine IPs.
  Due to this, you are likely to run into a "host key mismatch" errors while deploying.
  I use `:g/^10.240.0./d` in Vim to clean it up.
  You can probably do the same with `sed` or similar software of your choice.

## Contributing

Make sure the `ci-lint` script passes.

## Acknowledgements

Both [Kubernetes The Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way)
and [Kubernetes The Hard Way on Bare Metal](https://github.com/Praqma/LearnKubernetes/blob/master/kamran/Kubernetes-The-Hard-Way-on-BareMetal.md)
helped me immensely in this project.
