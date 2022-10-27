#!/bin/bash

set -eux

ns1=ns1
ns2=ns2
ns3=ns3
intf1=eth1
intf2=eth2
intf3=eth3
intf1ip6=2001:0:0:140::fd/64
intf1ip4=192.168.140.253/24
intf2ip6=2001:0:0:140::fe/64
intf2ip4=192.168.140.254/24
intf3ip6=2001:0:0:141::fe/64
intf3ip4=192.168.141.254/24

radvdprefix=2001:0:0:140::/64
radvdprefix3=2001:0:0:141::/64

killall radvd || true
killall dnsmasq || true
ip netns del $ns1 || true
ip netns del $ns2 || true
ip netns del $ns3 || true
ip link del veth-$ns1-host || true
ip link del veth-$ns2-host || true
ip link del veth-$ns3-host || true

ip netns add $ns1
ip netns exec $ns1 bash -c "echo 0 > /proc/sys/net/ipv6/conf/all/accept_ra"
ip netns exec $ns1 bash -c "echo 0 > /proc/sys/net/ipv6/conf/all/autoconf"
ip netns exec $ns1 bash -c "echo 1 > /proc/sys/net/ipv6/conf/all/forwarding"
ip link set dev $intf1 down
ip -6 a flush dev $intf1
ip link set $intf1 netns $ns1
ip netns exec $ns1 ip link set dev lo up
ip netns exec $ns1 ip link set dev $intf1 up
ip netns exec $ns1 ip a a dev $intf1 $intf1ip4
ip netns exec $ns1 ip -6 a a dev $intf1 $intf1ip6
ip link add veth-$ns1-host type veth peer veth-$ns1-ns
ip link set veth-$ns1-ns netns $ns1
ip a a dev veth-$ns1-host 192.0.2.1/30
ip netns exec $ns1 ip a a dev veth-$ns1-ns 192.0.2.2/30
ip link set dev veth-$ns1-host up
ip netns exec $ns1 ip link set dev veth-$ns1-ns up
ip netns exec $ns1 ip route add default via 192.0.2.1
ip netns exec $ns1 iptables -t nat -I POSTROUTING -o veth-$ns1-ns -j MASQUERADE
ip netns exec $ns1 sysctl -w net.ipv4.ip_forward=1

ip netns add $ns2 || true
ip netns exec $ns2 bash -c "echo 0 > /proc/sys/net/ipv6/conf/all/accept_ra"
ip netns exec $ns2 bash -c "echo 0 > /proc/sys/net/ipv6/conf/all/autoconf"
ip netns exec $ns2 bash -c "echo 1 > /proc/sys/net/ipv6/conf/all/forwarding"
ip link set dev $intf2 down
ip -6 a flush dev $intf2
ip link set $intf2 netns $ns2 || true
ip netns exec $ns2 ip link set dev lo up
ip netns exec $ns2 ip link set dev $intf2 up
ip netns exec $ns2 ip a a dev $intf2 $intf2ip4
ip netns exec $ns2 ip -6 a a dev $intf2 $intf2ip6
ip link add veth-$ns2-host type veth peer veth-$ns2-ns
ip link set veth-$ns2-ns netns $ns2
ip a a dev veth-$ns2-host 192.0.2.5/30
ip netns exec $ns2 ip a a dev veth-$ns2-ns 192.0.2.6/30
ip link set dev veth-$ns2-host up
ip netns exec $ns2 ip link set dev veth-$ns2-ns up
ip netns exec $ns2 ip route add default via 192.0.2.5
ip netns exec $ns2 iptables -t nat -I POSTROUTING -o veth-$ns2-ns -j MASQUERADE
ip netns exec $ns2 sysctl -w net.ipv4.ip_forward=1

ip netns add $ns3 || true
ip netns exec $ns3 bash -c "echo 0 > /proc/sys/net/ipv6/conf/all/accept_ra"
ip netns exec $ns3 bash -c "echo 0 > /proc/sys/net/ipv6/conf/all/autoconf"
ip netns exec $ns3 bash -c "echo 1 > /proc/sys/net/ipv6/conf/all/forwarding"
ip link set dev $intf3 down
ip -6 a flush dev $intf3
ip link set $intf3 netns $ns3 || true
ip netns exec $ns3 ip link set dev lo up
ip netns exec $ns3 ip link set dev $intf3 up
ip netns exec $ns3 ip a a dev $intf3 $intf3ip4
ip netns exec $ns3 ip -6 a a dev $intf3 $intf3ip6
ip link add veth-$ns3-host type veth peer veth-$ns3-ns
ip link set veth-$ns3-ns netns $ns3
ip a a dev veth-$ns3-host 192.0.2.9/30
ip netns exec $ns3 ip a a dev veth-$ns3-ns 192.0.2.10/30
ip link set dev veth-$ns3-host up
ip netns exec $ns3 ip link set dev veth-$ns3-ns up
ip netns exec $ns3 ip route add default via 192.0.2.9
ip netns exec $ns3 iptables -t nat -I POSTROUTING -o veth-$ns3-ns -j MASQUERADE
ip netns exec $ns3 sysctl -w net.ipv4.ip_forward=1

for intf in $intf1 $intf2; do
  cat <<EOF > /etc/radvd-$intf
interface $intf
{
	AdvSendAdvert on;
	MinRtrAdvInterval 30;
	MaxRtrAdvInterval 100;
	prefix $radvdprefix
	{
		AdvOnLink on;
		AdvAutonomous on;
		AdvRouterAddr off;
	};

};
EOF

  cat <<EOF > /etc/dnsmasq-$intf.conf
# To disable dnsmasq's DNS server functionality.
port=0

# To enable dnsmasq's DHCP server functionality.
dhcp-range=192.168.140.50,192.168.140.150,255.255.255.0,1h
# dhcp-option=3,192.168.140.253,192.168.140.254
# dhcp-option=121,0.0.0.0/0,192.168.140.253,0.0.0.0/0,192.168.140.254
dhcp-option=6,8.8.8.8
EOF
done

for intf in $intf3; do
  cat <<EOF > /etc/radvd-$intf
interface $intf
{
	AdvSendAdvert on;
	MinRtrAdvInterval 30;
	MaxRtrAdvInterval 100;
	prefix $radvdprefix3
	{
		AdvOnLink on;
		AdvAutonomous on;
		AdvRouterAddr off;
	};

};
EOF

  cat <<EOF > /etc/dnsmasq-$intf3.conf
# To disable dnsmasq's DNS server functionality.
port=0

# To enable dnsmasq's DHCP server functionality.
dhcp-range=192.168.141.50,192.168.141.150,255.255.255.0,1h
# dhcp-option=3,192.168.141.253,192.168.141.254
# dhcp-option=121,0.0.0.0/0,192.168.141.253,0.0.0.0/0,192.168.141.254
dhcp-option=6,8.8.8.8
EOF
done

ip netns exec $ns1 radvd -C /etc/radvd-$intf1 -p /run/radvd/radvd-$intf1.pid
ip netns exec $ns1 dnsmasq -C /etc/dnsmasq-$intf1.conf -x /run/dnsmasq-$intf1.pid
# ip netns exec $ns2 radvd -C /etc/radvd-$intf2 -p /run/radvd/radvd-$intf2.pid
# ip netns exec $ns2 dnsmasq -C /etc/dnsmasq-$intf2.conf -x /run/dnsmasq-$intf2.pid
ip netns exec $ns3 radvd -C /etc/radvd-$intf3 -p /run/radvd/radvd-$intf3.pid
ip netns exec $ns3 dnsmasq -C /etc/dnsmasq-$intf3.conf -x /run/dnsmasq-$intf3.pid

echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -I POSTROUTING -o eth0 -j MASQUERADE

sleep infinity
