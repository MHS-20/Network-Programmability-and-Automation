# create namespace
sudo ip netns add H1
sudo ip netns add H2

# create bridge
sudo ip link add SW1 type bridge

# create veth and attach to namespace
sudo ip link add veth1 address 00:00:00:11:11:11 type veth peer name eth-H1 # first cable
sudo ip link set veth1 netns H1
sudo ip netns exec H1 ip link set veth1 up

# attach to bridge
sudo ip link set eth-H1 master SW1
sudo ip link set eth-H1 up

# create second cable and attach to H2
sudo ip link add veth2 address 00:00:00:22:22:22 type veth peer name eth-H2 # second cable
sudo ip link set veth2 netns H2
sudo ip netns exec H2 ip link set veth2 up
sudo ip link set eth-H2 master SW1
sudo ip link set eth-H2 up

# show bridge (doesn't have an ip, but it's connected to kernel switch)
sudo ip link set SW1 up
sudo bridge link

# assign ip address
sudo ip netns exec H1 ip addr add 172.0.0.1/30 dev veth1
sudo ip netns exec H2 ip addr add 172.0.0.2/30 dev veth2

# test connectivity
sudo ip netns exec H1 ping 172.0.0.2

# routes
sudo ip netns exec H1 ip route
sudo ip netns exec H2 ip route