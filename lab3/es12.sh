#!/bin/bash
sudo ip netns add H11
sudo ip netns add H12
sudo ip netns add H21
sudo ip netns add H22

sudo ovs-vsctl add-br SW1
sudo ovs-vsctl add-br SW2

# H11 -> SW1 access VLAN 10
sudo ip link add veth-H11 address "00:00:00:11:11:11" type veth peer name eth-H11
sudo ip link set veth-H11 netns H11
sudo ip netns exec H11 ip link set veth-H11 up
sudo ovs-vsctl add-port SW1 eth-H11 tag=10
sudo ip link set eth-H11 up

# H12 -> SW2 access VLAN 10
sudo ip link add veth-H12 address "00:00:00:12:12:12" type veth peer name eth-H12
sudo ip link set veth-H12 netns H12
sudo ip netns exec H12 ip link set veth-H12 up
sudo ovs-vsctl add-port SW2 eth-H12 tag=10
sudo ip link set eth-H12 up

# H21 -> SW1 access VLAN 20
sudo ip link add veth-H21 address "00:00:00:21:21:21" type veth peer name eth-H21
sudo ip link set veth-H21 netns H21
sudo ip netns exec H21 ip link set veth-H21 up
sudo ovs-vsctl add-port SW1 eth-H21 tag=20
sudo ip link set eth-H21 up

# H22 -> SW2 access VLAN 20
sudo ip link add veth-H22 address "00:00:00:22:22:22" type veth peer name eth-H22
sudo ip link set veth-H22 netns H22
sudo ip netns exec H22 ip link set veth-H22 up
sudo ovs-vsctl add-port SW2 eth-H22 tag=20
sudo ip link set eth-H22 up

# Trunk SW1 <-> SW2 for VLANs 10 and 20
sudo ip link add sw1-trunk type veth peer name sw2-trunk
sudo ovs-vsctl add-port SW1 sw1-trunk trunks=10,20
sudo ovs-vsctl add-port SW2 sw2-trunk trunks=10,20
sudo ip link set sw1-trunk up
sudo ip link set sw2-trunk up

sudo ip link set SW1 up
sudo ip link set SW2 up

sudo ip netns exec H11 ip addr add 10.0.10.11/24 dev veth-H11
sudo ip netns exec H12 ip addr add 10.0.10.12/24 dev veth-H12
sudo ip netns exec H21 ip addr add 10.0.20.21/24 dev veth-H21
sudo ip netns exec H22 ip addr add 10.0.20.22/24 dev veth-H22

# Quick checks: same VLAN across switches should work; cross-VLAN should fail (no router configured).
sudo ip netns exec H11 ping -c3 10.0.10.12
sudo ip netns exec H21 ping -c3 10.0.20.22
sudo ip netns exec H11 ping -c3 10.0.20.21
