#!/bin/sh

user=$1

if [ -z "$user" ]; then
	echo "Please call '$0 <user>' to run this command!"
	exit 1
fi

mkdir -p /etc/wireguard/clients/$user
cd /etc/wireguard/clients/$user
umask 077; wg genkey | tee privatekey | wg pubkey > publickey

count=$(ls /etc/wireguard/clients | wc -l)
count=$((count+1))

cat > "$user.conf" <<EOF
[Interface]
PrivateKey = $(cat privatekey)
Address = 192.168.44.$count/24

[Peer]
PublicKey = $(cat /etc/wireguard/publickey)
Endpoint = 193.198.39.246:51820
AllowedIPs = 192.168.88.0/24
EOF

cat >> /etc/wireguard/wg0.conf << EOF

# $user
[Peer]
PublicKey = $(cat publickey)
AllowedIPs = 192.168.44.$count
EOF

systemctl restart wg-quick@wg0

cat "$user.conf"
