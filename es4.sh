# create namespaces
sudo ip netns add H1
sudo ip netns add H2
sudo ip netns add H3
sudo ip netns add H4

# create OVS bridge
sudo ovs-vsctl add-br SW1

# --- H1 ---
sudo ip link add veth1 type veth peer name eth-H1
sudo ip link set veth1 netns H1
sudo ip netns exec H1 ip link set veth1 up
sudo ovs-vsctl add-port SW1 eth-H1
sudo ip link set eth-H1 up

# --- H2 ---
sudo ip link add veth2 type veth peer name eth-H2
sudo ip link set veth2 netns H2
sudo ip netns exec H2 ip link set veth2 up
sudo ovs-vsctl add-port SW1 eth-H2
sudo ip link set eth-H2 up

# --- H3 ---
sudo ip link add veth3 type veth peer name eth-H3
sudo ip link set veth3 netns H3
sudo ip netns exec H3 ip link set veth3 up
sudo ovs-vsctl add-port SW1 eth-H3
sudo ip link set eth-H3 up

# --- H4 ---
sudo ip link add veth4 type veth peer name eth-H4
sudo ip link set veth4 netns H4
sudo ip netns exec H4 ip link set veth4 up
sudo ovs-vsctl add-port SW1 eth-H4
sudo ip link set eth-H4 up

# bring up the bridge
sudo ip link set SW1 up

# assign IP addresses (10.0.1.0/24)
sudo ip netns exec H1 ip addr add 10.0.1.1/24 dev veth1
sudo ip netns exec H2 ip addr add 10.0.1.2/24 dev veth2
sudo ip netns exec H3 ip addr add 10.0.1.3/24 dev veth3
sudo ip netns exec H4 ip addr add 10.0.1.4/24 dev veth4

# verify topology
sudo ovs-vsctl show

# test connectivity (tutti devono rispondere)
sudo ip netns exec H1 ping 10.0.1.2
sudo ip netns exec H1 ping 10.0.1.3
sudo ip netns exec H1 ping 10.0.1.4