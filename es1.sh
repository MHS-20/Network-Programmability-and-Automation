# create namespace
sudo ipnets add H1
sudo ipnets add H2

# create veths and attach to namespace
sudo ip link add veth1 type veth peer name veth2
sudo ip link set veth1 netns H1
sudo ip link set veth2 netns H2

# exec set up, inside namespace
sudo ip netns exec H1 ip link set veth1 up
sudo ip netns exec H2 ip link set veth2 up

# assign ip address
sudo ip netns exec H1 ip addr add 172.0.0.1/30 dev veth1
sudo ip netns exec H2 ip addr add 172.0.0.2/30 dev veth2

# test connectivity
sudo ip netns exec H1 ping 172.0.0.2

# using wireshark inside namespace
sudo ip netns exec H1 wireshark

# delete -all 