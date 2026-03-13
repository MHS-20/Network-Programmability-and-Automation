#!/bin/bash

# ── Namespaces ────────────────────────────────────────────
sudo ip netns add H11
sudo ip netns add H12
sudo ip netns add H21
sudo ip netns add H22
sudo ip netns add R1
sudo ip netns add R2
sudo ip netns add R3

# ── Switches ──────────────────────────────────────────────
sudo ovs-vsctl add-br SW1
sudo ovs-vsctl add-br SW2

# ── Hosts on SW1 ──────────────────────────────────────────
sudo ip link add veth0 address "00:00:00:11:11:11" type veth peer name eth-H11
sudo ip link set veth0 netns H11
sudo ip netns exec H11 ip link set veth0 up
sudo ovs-vsctl add-port SW1 eth-H11
sudo ip link set eth-H11 up

sudo ip link add veth0 address "00:00:00:12:12:12" type veth peer name eth-H12
sudo ip link set veth0 netns H12
sudo ip netns exec H12 ip link set veth0 up
sudo ovs-vsctl add-port SW1 eth-H12
sudo ip link set eth-H12 up

# ── Hosts on SW2 ──────────────────────────────────────────
sudo ip link add veth0 address "00:00:00:21:21:21" type veth peer name eth-H21
sudo ip link set veth0 netns H21
sudo ip netns exec H21 ip link set veth0 up
sudo ovs-vsctl add-port SW2 eth-H21
sudo ip link set eth-H21 up

sudo ip link add veth0 address "00:00:00:22:22:22" type veth peer name eth-H22
sudo ip link set veth0 netns H22
sudo ip netns exec H22 ip link set veth0 up
sudo ovs-vsctl add-port SW2 eth-H22
sudo ip link set eth-H22 up

# ── R1 ↔ SW1 ──────────────────────────────────────────────
sudo ip link add veth-R1-sw address "00:00:00:aa:aa:aa" type veth peer name eth-R1-sw
sudo ip link set veth-R1-sw netns R1
sudo ip netns exec R1 ip link set veth-R1-sw up
sudo ovs-vsctl add-port SW1 eth-R1-sw
sudo ip link set eth-R1-sw up

# ── R2 ↔ SW2 ──────────────────────────────────────────────
sudo ip link add veth-R2-sw address "00:00:00:bb:bb:bb" type veth peer name eth-R2-sw
sudo ip link set veth-R2-sw netns R2
sudo ip netns exec R2 ip link set veth-R2-sw up
sudo ovs-vsctl add-port SW2 eth-R2-sw
sudo ip link set eth-R2-sw up

# ── R1 ↔ R3 (192.168.0.0/30) ─────────────────────────────
sudo ip link add veth-R1-R3 address "00:00:00:cc:cc:01" type veth peer name veth-R3-R1 address "00:00:00:cc:cc:02"
sudo ip link set veth-R1-R3 netns R1
sudo ip link set veth-R3-R1 netns R3
sudo ip netns exec R1 ip link set veth-R1-R3 up
sudo ip netns exec R3 ip link set veth-R3-R1 up

# ── R2 ↔ R3 (192.168.0.4/30) ─────────────────────────────
sudo ip link add veth-R2-R3 address "00:00:00:dd:dd:01" type veth peer name veth-R3-R2 address "00:00:00:dd:dd:02"
sudo ip link set veth-R2-R3 netns R2
sudo ip link set veth-R3-R2 netns R3
sudo ip netns exec R2 ip link set veth-R2-R3 up
sudo ip netns exec R3 ip link set veth-R3-R2 up

# ── IP Addresses ──────────────────────────────────────────
# Hosts
sudo ip netns exec H11 ip addr add 10.0.1.1/24 dev veth0
sudo ip netns exec H12 ip addr add 10.0.1.2/24 dev veth0
sudo ip netns exec H21 ip addr add 10.0.2.1/24 dev veth0
sudo ip netns exec H22 ip addr add 10.0.2.2/24 dev veth0

# R1
sudo ip netns exec R1 ip addr add 10.0.1.254/24   dev veth-R1-sw   # LAN side → SW1
sudo ip netns exec R1 ip addr add 192.168.0.1/30  dev veth-R1-R3   # WAN side → R3

# R2
sudo ip netns exec R2 ip addr add 10.0.2.254/24   dev veth-R2-sw   # LAN side → SW2
sudo ip netns exec R2 ip addr add 192.168.0.5/30  dev veth-R2-R3   # WAN side → R3

# R3
sudo ip netns exec R3 ip addr add 192.168.0.2/30  dev veth-R3-R1   # toward R1
sudo ip netns exec R3 ip addr add 192.168.0.6/30  dev veth-R3-R2   # toward R2

# ── IP Forwarding ─────────────────────────────────────────
sudo ip netns exec R1 sysctl -w net.ipv4.ip_forward=1
sudo ip netns exec R2 sysctl -w net.ipv4.ip_forward=1
sudo ip netns exec R3 sysctl -w net.ipv4.ip_forward=1

# ── Routing ───────────────────────────────────────────────
# Hosts: default GW = their local router
sudo ip netns exec H11 ip route add default via 10.0.1.254
sudo ip netns exec H12 ip route add default via 10.0.1.254
sudo ip netns exec H21 ip route add default via 10.0.2.254
sudo ip netns exec H22 ip route add default via 10.0.2.254

# R1: unknown traffic → R3
sudo ip netns exec R1 ip route add default via 192.168.0.2

# R2: unknown traffic → R3
sudo ip netns exec R2 ip route add default via 192.168.0.6

# R3: explicit routes to each LAN (not needed with GRE tunnel)
# sudo ip netns exec R3 ip route add 10.0.1.0/24 via 192.168.0.1   # via R1
# sudo ip netns exec R3 ip route add 10.0.2.0/24 via 192.168.0.5   # via R2

# ── GRE Tunnel R1 ↔ R2 ────────────────────────────────────
# R1 side
sudo ip netns exec R1 ip tunnel add gre1 \
    mode gre \
    local 192.168.0.1 \
    remote 192.168.0.5 \
    ttl 255

sudo ip netns exec R1 ip addr add 172.16.0.1/30 dev gre1
sudo ip netns exec R1 ip link set gre1 up

# R2 side
sudo ip netns exec R2 ip tunnel add gre1 \
    mode gre \
    local 192.168.0.5 \
    remote 192.168.0.1 \
    ttl 255

sudo ip netns exec R2 ip addr add 172.16.0.2/30 dev gre1
sudo ip netns exec R2 ip link set gre1 up

sudo ip netns exec R1 ip route add 10.0.2.0/24 via 172.16.0.2 # R1 → LAN2 via GRE
sudo ip netns exec R2 ip route add 10.0.1.0/24 via 172.16.0.1 # R2 → LAN1 via GRE

# ── Test Connectivity ─────────────────────────────────────
sudo ip netns exec H11 ping -c3 10.0.1.2    # H11 → H12 (same LAN)
sudo ip netns exec H11 ping -c3 10.0.2.1    # H11 → H21 (cross LAN)
sudo ip netns exec H11 ping -c3 10.0.2.2    # H11 → H22 (cross LAN)