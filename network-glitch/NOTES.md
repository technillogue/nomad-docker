# overview

problems in total:

1. MTU 1280 on server vs 1800 on client (ran into this trying to do wireguard on DSL)
2. server sets icmp_echo_ignore_all 
3. server blocks incoming 8080 on wg0
4. server blocks ipv6 udp 51820, needed for wireguard 
5. client also blocks udp traffic
6. client wg config doesn't specify server endpoint
7. client seems to be trying to route 192.168 through 172.19 (?). this can be fixed by instead just changing the wireguard config

# work notes

no /usr/local/bin/setup.sh (despite the copy?)

can't find a reference to TYPE=SERVER

okay, it's deleted on startup, cool

different MTU

server blocks incoming 8080 on wg0
and ipv6 udp 51820 (wg port)
fix: 
```bash
iptables -D INPUT 1
ip6tables -D INPUT 1
```

client blocks incoming wg traffic 
routes 192.168 through 172.19 (??)
fix:
```
ip6tables -D INPUT 1
```

to block 6pn on the client:
`ip6tables -A OUTPUT -p tcp -m tcp --dport 8080 -j DROP`
or on the server:
`ip6tables -A INPUT -i eth0 -p tcp -m tcp --dport 8080 -j DROP`

server blocks pings: `sysctl net.ipv4.icmp_echo_ignore_all=1`

ip route del 192.168.0.1

Endpoint = sre-network-server-sylv.internal:51820

one solution: change server to be 192.168 (maybe not in the spirit of the problem?)
