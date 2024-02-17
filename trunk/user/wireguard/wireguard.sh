#!/bin/sh

start_wg() {
	localip="$(nvram get wireguard_localip)"
	listenport="$(nvram get wireguard_port)"
	privatekey="$(nvram get wireguard_localkey)"
	peerkey="$(nvram get wireguard_peerkey)"
	presharedkey="$(nvram get wireguard_prekey)"
	peerip="$(nvram get wireguard_peerip)"
	if [ -z $localip ] || [ -z $privatekey ] || [ -z $peerkey ]; then
	 logger -t "WIREGUARD" "Start Error"
		exit 0
	fi
	logger -t "WIREGUARD" "Wireguard Startting"
	ip link show wg0 >/dev/null 2>&1 && ip link set dev wg0 down && ip link del dev wg0
	ip link add dev wg0 type wireguard
	ip link set dev wg0 mtu 1420
	ip addr add $localip dev wg0
 if [ -z $listenport ]; then listenport=51820; fi
	echo "$privatekey" > /tmp/privatekey
	wg set wg0 listen-port $listenport private-key /tmp/privatekey
	if [ "$presharedkey" ]; then
	 echo "$presharedkey" > /tmp/presharedkey
		wg set wg0 peer $peerkey preshared-key /tmp/presharedkey
	fi
	wg set wg0 peer $peerkey persistent-keepalive 25 allowed-ips 0.0.0.0/0 endpoint $peerip
	ip link set dev wg0 up
	iptables -A INPUT -i wg0 -j ACCEPT
	iptables -A FORWARD -i wg0 -j ACCEPT
	iptables -t nat -A POSTROUTING -o wg0 -j MASQUERADE
		
}


stop_wg() {
	if [ ip link show wg0 >/dev/null 2>&1 ]; then
		iptables -D INPUT -i wg0 -j ACCEPT
		iptables -D FORWARD -i wg0 -j ACCEPT
		iptables -t nat -D POSTROUTING -o wg0 -j MASQUERADE
		ip link set dev wg0 down
		ip link del dev wg0
		logger -t "WIREGUARD" "已经关闭wireguard"
	fi
	}



case $1 in
start)
	start_wg
	;;
stop)
	stop_wg
	;;
*)
	echo "check"
	#exit 0
	;;
esac
