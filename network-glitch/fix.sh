#!/bin/bash
set -o xtrace
if [ "$TYPE" = "SERVER" ]; then
  # mv /etc/wireguard/wg0-1.conf /etc/wireguard/wg0.conf
  # wg-quick up wg0
  # iptables -A INPUT -i wg0 -p tcp -m tcp --dport 8080 -j DROP
  # ip6tables -A INPUT -m udp -p udp --dport 51820 -j DROP
  iptables -D INPUT 1 # don't block wg0 tcp
  ip6tables -D INPUT 1 # don't block udp from wg
  ip6tables -A INPUT -i eth0 -p tcp -m tcp --dport 8080 -j DROP # block 6pn http
  sysctl net.ipv4.icmp_echo_ignore_all=0(wg port) # allow pings
else
  # mv /etc/wireguard/wg0-2.conf /etc/wireguard/wg0.conf
  # wg-quick up wg0
  # ip6tables -A INPUT -m udp -p udp --dport 51820 -j DROP
  # ip route add 192.168.0.1/32 via "$(ip a s|grep 172.19|awk '{print $2}'|head -n1|sed 's/\/29$//')"
  ip6tables -D INPUT 1 # don't block incoming udp traffic from wg
  ip route del 192.168.0.1 # no route
  sed -i 's/10.0/192.168/' /etc/wireguard/wg0.conf # cheating?
  echo >> /etc/wireguard/wg0.conf # no newline
  echo "Endpoint = sre-network-server-sylv.internal:51820" >> /etc/wireguard/wg0.conf
fi
