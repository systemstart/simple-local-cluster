# Simple Local Cluster

Easy-ish to use containerized cluster setup using [Docker Compose](https://docs.docker.com/compose/) and [k3s](https://k3s.io/).

### Table of Contents
1. [Motivation](#motivation)
2. [Usage](#usage)
   1. [Configuration](#configuration)
   2. [Host Setup](#host-setup)
   3. [Running](#running)

# Motivation

To develop apps to be deployed to [Kubernetes](https://kubernetes.io/) one might need a simple way to create a cluster with certain capabilities.

To do this there is many great options like [Kind](https://kind.sigs.k8s.io/), [K3D](https://k3d.io/) and many more.

**So why another option?**

This repository offers a simple [Docker Compose](https://docs.docker.com/compose/) based solution with these
features:

* Direct access to app via port mapping, no additional Load Balancer needed
* Basic PKI infrastructure for TLS/HTTPS
* Simple DNS Server

# Usage

## Prerequisites

You will need:
* [Docker](https://www.docker.com/)
* [Docker Compose](https://docs.docker.com/compose/)
* [Make](https://www.gnu.org/software/make/)
* [kubectl](https://kubernetes.io/docs/reference/kubectl/)

## Configuration

Copy [example.env](./example.env) to `.env` and change to fit your needs.

You can probably use the defaults:
* `PRIVATE_IP=127.0.0.1`
 
    The [kubeapi](https://kubernetes.io/docs/reference/using-api/) is bound to this with port 6443 

* `PUBLIC_IP=127.0.0.1`

    This is the "public" facing IP to point your browser to when accessing App UIs running in the cluster

* `DOMAIN=my-project.intern`

    The domain name where our Apps should be reachable, the DNS container
    will resolve everything under this domain to `PUBLIC_IP`.

## Host Setup

To make use of the included DNS server your host system needs to know about
it, so it knows that every DNS request for `DOMAIN`(from your `.env`) should be 
forwarded to `PUBLIC_IP:1053`.

If you are using Linux you might have one of the following options available. 

**Attention**: these examples are held very simple and might **absolutely not fit
your Linux distro**. Make sure to consult its documentation if unsure.

### `dnsmasq`

Create the file `/etc/dnsmasq.d/my-project.intern`(or what you set `DOMAIN` to), 
with the following line(fix to match your `DOMAIN` and `PUBLIC_IP`):

```
server=/my-project.intern/127.0.0.1:1053
```

Then restart `dnsmasq` with 
```
systemctl restart dnsmasq.service
```

See it's [manpage](https://dnsmasq.org/docs/dnsmasq-man.html) for details.
and/or consult your distro's documentation.

### `systemd-resolved`

Edit the file `/etc/systemd/resolved.conf`, find the `[Resolve]` block and add this
(fix to match your `DOMAIN` and `PUBLIC_IP`):

```
DNS=127.0.0.1:1053#my-project.intern
```

## Running

Start cluster with:
```
make up
```

Check logs:
```
make tail
```

Get kubeconfig with:
```
make get-kubeconfig
```

Install 3rd party manifests(only need on first startup):
```
make install-3rdparty
```

Get pods:
```
kubectl --kubeconfig .kubeconfig get pods -A
```

## PKI

If you point your browser at `http://$DOMAIN`(your domain name from `.env`, without HTTPS(!)), you will
find a link to download the certificate of a CA used in the cluster for ingresses. This can be installed
in the browser or some local certificate store.

## Cleanup

Run `make rm` to delete everything but the k3s server volume.

## Troubleshooting

If your kubeapi client runs into something like this:
```
Unable to connect to the server: tls: failed to verify certificate: x509: certificate signed by unknown authority
```
You might have a leftover `.kubeconfig` file, make sure to delete it manually and run `make get-kubeconfig` again.
