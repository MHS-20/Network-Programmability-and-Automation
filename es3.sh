# create namespaces
sudo ip netns add H1
sudo ip netns add H2

# create OVS bridge (switch)
sudo ovs-vsctl add-br SW1

# create veth pairs and attach to namespaces
sudo ip link add veth1 address 00:00:00:11:11:11 type veth peer name eth-H1
sudo ip link set veth1 netns H1
sudo ip netns exec H1 ip link set veth1 up

sudo ip link add veth2 address 00:00:00:22:22:22 type veth peer name eth-H2
sudo ip link set veth2 netns H2
sudo ip netns exec H2 ip link set veth2 up

# attach veth peers to OVS bridge
sudo ovs-vsctl add-port SW1 eth-H1
sudo ovs-vsctl add-port SW1 eth-H2

# bring up the ports and the bridge
sudo ip link set eth-H1 up
sudo ip link set eth-H2 up
sudo ip link set SW1 up

# show OVS bridge and ports
sudo ovs-vsctl show
sudo ovs-ofctl show SW1

# assign ip addresses
sudo ip netns exec H1 ip addr add 172.0.0.1/30 dev veth1
sudo ip netns exec H2 ip addr add 172.0.0.2/30 dev veth2

# test connectivity
sudo ip netns exec H1 ping 172.0.0.2

# routes
sudo ip netns exec H1 ip route
sudo ip netns exec H2 ip route