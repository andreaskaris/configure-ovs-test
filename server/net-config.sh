#!/bin/bash

set -eux

ns1=ns1
ns2=ns2
intf1=eth1
intf2=eth2
intf1ip6=2001::fd/64
intf1ip4=192.168.140.253/24
intf2ip6=2001::fe/64
intf2ip4=192.168.140.254/24
radvdprefix=2001::/64

killall radvd || true
killall dnsmasq || true
ip netns del $ns1 || true
ip netns del $ns2 || true

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
dhcp-option=121,0.0.0.0/0,192.168.140.253,0.0.0.0/0,192.168.140.254
EOF
done

ip netns exec $ns1 radvd -C /etc/radvd-$intf1 -p /run/radvd/radvd-$intf1.pid
ip netns exec $ns1 dnsmasq -C /etc/dnsmasq-$intf1.conf -x /run/dnsmasq-$intf1.pid
ip netns exec $ns2 radvd -C /etc/radvd-$intf2 -p /run/radvd/radvd-$intf2.pid
# ip netns exec $ns2 dnsmasq -C /etc/dnsmasq-$intf2.conf -x /run/dnsmasq-$intf2.pid
sleep infinity
