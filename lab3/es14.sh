#!/bin/bash

# -----------------------
# Namespaces
# -----------------------
sudo ip netns add H1
sudo ip netns add H2
sudo ip netns add H3
sudo ip netns add H4
sudo ip netns add H5
sudo ip netns add H6
sudo ip netns add R1


# -----------------------
# Switches
# -----------------------
sudo ovs-vsctl add-br SW1
sudo ovs-vsctl add-br SW2
sudo ovs-vsctl add-br SW3


# -----------------------
# HOSTS SW1 (VLAN 10)
# -----------------------
sudo ip link add veth1 type veth peer name eth-H1
sudo ip link set veth1 netns H1
sudo ip netns exec H1 ip link set veth1 up
sudo ovs-vsctl add-port SW1 eth-H1 tag=10
sudo ip link set eth-H1 up

sudo ip link add veth2 type veth peer name eth-H2
sudo ip link set veth2 netns H2
sudo ip netns exec H2 ip link set veth2 up
sudo ovs-vsctl add-port SW1 eth-H2 tag=10
sudo ip link set eth-H2 up


# -----------------------
# HOSTS SW2 (VLAN 20)
# -----------------------
sudo ip link add veth3 type veth peer name eth-H3
sudo ip link set veth3 netns H3
sudo ip netns exec H3 ip link set veth3 up
sudo ovs-vsctl add-port SW2 eth-H3 tag=20
sudo ip link set eth-H3 up

sudo ip link add veth4 type veth peer name eth-H4
sudo ip link set veth4 netns H4
sudo ip netns exec H4 ip link set veth4 up
sudo ovs-vsctl add-port SW2 eth-H4 tag=20
sudo ip link set eth-H4 up


# -----------------------
# HOSTS SW3 (VLAN 30)
# -----------------------
sudo ip link add veth5 type veth peer name eth-H5
sudo ip link set veth5 netns H5
sudo ip netns exec H5 ip link set veth5 up
sudo ovs-vsctl add-port SW3 eth-H5 tag=30
sudo ip link set eth-H5 up

sudo ip link add veth6 type veth peer name eth-H6
sudo ip link set veth6 netns H6
sudo ip netns exec H6 ip link set veth6 up
sudo ovs-vsctl add-port SW3 eth-H6 tag=30
sudo ip link set eth-H6 up


# -----------------------
# SWITCH LINKS (TRUNK)
# -----------------------
# SW1 <-> SW2
sudo ip link add sw1-sw2 type veth peer name sw2-sw1
sudo ovs-vsctl add-port SW1 sw1-sw2 trunks=10,20,30
sudo ovs-vsctl add-port SW2 sw2-sw1 trunks=10,20,30
sudo ip link set sw1-sw2 up
sudo ip link set sw2-sw1 up

# SW2 <-> SW3
sudo ip link add sw2-sw3 type veth peer name sw3-sw2
sudo ovs-vsctl add-port SW2 sw2-sw3 trunks=10,20,30
sudo ovs-vsctl add-port SW3 sw3-sw2 trunks=10,20,30
sudo ip link set sw2-sw3 up
sudo ip link set sw3-sw2 up

# -----------------------
# ROUTER CONNECTION
# -----------------------
sudo ip link add r1-eth0 type veth peer name sw1-r1
sudo ip link set r1-eth0 netns R1
sudo ip netns exec R1 ip link set r1-eth0 up

sudo ovs-vsctl add-port SW1 sw1-r1 trunks=10,20,30
sudo ip link set sw1-r1 up


# -----------------------
# Router VLAN interfaces
# -----------------------
sudo ip netns exec R1 ip link add link r1-eth0 name r1-eth0.10 type vlan id 10
sudo ip netns exec R1 ip link add link r1-eth0 name r1-eth0.20 type vlan id 20
sudo ip netns exec R1 ip link add link r1-eth0 name r1-eth0.30 type vlan id 30

sudo ip netns exec R1 ip link set r1-eth0.10 up
sudo ip netns exec R1 ip link set r1-eth0.20 up
sudo ip netns exec R1 ip link set r1-eth0.30 up


# -----------------------
# IP ADDRESSES
# -----------------------
sudo ip netns exec H1 ip addr add 10.0.1.1/24 dev veth1
sudo ip netns exec H2 ip addr add 10.0.1.2/24 dev veth2

sudo ip netns exec H3 ip addr add 10.0.2.1/24 dev veth3
sudo ip netns exec H4 ip addr add 10.0.2.2/24 dev veth4

sudo ip netns exec H5 ip addr add 10.0.3.1/24 dev veth5
sudo ip netns exec H6 ip addr add 10.0.3.2/24 dev veth6


sudo ip netns exec R1 ip addr add 10.0.1.254/24 dev r1-eth0.10
sudo ip netns exec R1 ip addr add 10.0.2.254/24 dev r1-eth0.20
sudo ip netns exec R1 ip addr add 10.0.3.254/24 dev r1-eth0.30


# -----------------------
# Enable routing
# -----------------------
sudo ip netns exec R1 sysctl -w net.ipv4.ip_forward=1


# -----------------------
# Default gateways
# -----------------------
sudo ip netns exec H1 ip route add default via 10.0.1.254
sudo ip netns exec H2 ip route add default via 10.0.1.254

sudo ip netns exec H3 ip route add default via 10.0.2.254
sudo ip netns exec H4 ip route add default via 10.0.2.254

sudo ip netns exec H5 ip route add default via 10.0.3.254
sudo ip netns exec H6 ip route add default via 10.0.3.254


# -----------------------
# Bring switches up
# -----------------------
sudo ip link set SW1 up
sudo ip link set SW2 up
sudo ip link set SW3 up


# -----------------------
# TEST
# -----------------------
sudo ip netns exec H1 ping -c3 10.0.1.2
sudo ip netns exec H1 ping -c3 10.0.2.1
sudo ip netns exec H1 ping -c3 10.0.3.1