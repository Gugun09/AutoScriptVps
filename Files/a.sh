#!/bin/bash
# Debian 8 - OVPN & Squid Proxy Installer
# Created by Daybreakersx

# Color
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

# get needed ip
MYIP=$(curl -4 icanhazip.com)
if [ $MYIP = "" ]; then
   MYIP=`ifconfig | grep 'inet addr:' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | cut -d: -f2 | awk '{ print $1}' | head -1`;
fi
MYIP2="s/xxxxxxxxx/$MYIP/g";

# os name & rclocal
OS=debian
RCLOCAL='/etc/rc.local'

# update package
apt-get update; apt-get -y upgrade;

# install openvpn
apt-get -y install openvpn unzip;

# download cert openvpn config
wget https://raw.githubusercontent.com/Clrkz/AutoScriptVPS/master/Files/Certificate/cert.zip -O trinityfreevpn.zip
unzip trinityfreevpn.zip
rm zip*
cp -r config/* /etc/openvpn
cd /root
chmod -R 755 /etc/openvpn

# Creating OpenVPN Config
cat > /root/client.ovpn <<-END
client
dev tun
proto tcp
remote $MYIP 443
resolv-retry infinite
redirect-gateway def1
nobind
sndbuf 393216
rcvbuf 393216
tun-mtu 1470
mssfix 1430
auth-user-pass
comp-lzo
http-proxy $MYIP 8000
http-proxy-retry
http-proxy-timeout 5
http-proxy-option CUSTOM-HEADER Host www.googlevideo.com
http-proxy-option CUSTOM-HEADER X-Online-Host www.googlevideo.com
route $MYIP 255.255.255.255 vpn_gateway
keepalive 10 120
reneg-sec 432000
verb 3
script-security 3
setenv CLIENT_CERT 0

END
echo '<ca>' >> /root/client.ovpn
cat /etc/openvpn/ca.crt >> /root/client.ovpn
echo '</ca>' >> /root/client.ovpn
cd

# Enable net.ipv4.ip_forward 
sed -i '/\<net.ipv4.ip_forward\>/c\net.ipv4.ip_forward=1' /etc/sysctl.conf
	if ! grep -q "\<net.ipv4.ip_forward\>" /etc/sysctl.conf; then
		echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
	fi

	echo 1 > /proc/sys/net/ipv4/ip_forward
	if pgrep firewalld; then
		firewall-cmd --zone=public --add-port=443/tcp
		firewall-cmd --zone=trusted --add-source=10.8.0.0/24
		firewall-cmd --permanent --zone=public --add-port=443/tcp
		firewall-cmd --permanent --zone=trusted --add-source=10.8.0.0/24
		firewall-cmd --direct --add-rule ipv4 nat POSTROUTING 0 -s 10.8.0.0/24 ! -d 10.8.0.0/24 -j SNAT --to $MYIP
		firewall-cmd --permanent --direct --add-rule ipv4 nat POSTROUTING 0 -s 10.8.0.0/24 ! -d 10.8.0.0/24 -j SNAT --to $MYIP
	else
		if [[ "$OS" = 'debian' && ! -e $RCLOCAL ]]; then
			echo '#!/bin/sh -e
exit 0' > $RCLOCAL
		fi
		chmod +x $RCLOCAL

		iptables -t nat -A POSTROUTING -s 10.8.0.0/24 ! -d 10.8.0.0/24 -j SNAT --to $MYIP
		sed -i "1 a\iptables -t nat -A POSTROUTING -s 10.8.0.0/24 ! -d 10.8.0.0/24 -j SNAT --to $MYIP" $RCLOCAL
		if iptables -L -n | grep -qE '^(REJECT|DROP)'; then
			iptables -I INPUT -p tcp --dport 443 -j ACCEPT
			iptables -I FORWARD -s 10.8.0.0/24 -j ACCEPT
			iptables -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
			sed -i "1 a\iptables -I INPUT -p tcp --dport 443 -j ACCEPT" $RCLOCAL
			sed -i "1 a\iptables -I FORWARD -s 10.8.0.0/24 -j ACCEPT" $RCLOCAL
			sed -i "1 a\iptables -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT" $RCLOCAL
		fi
	fi

# Install Squid Proxy
apt-get -y install squid3
cat > /etc/squid3/squid.conf <<END
acl localnet src 10.8.0.0/24	# RFC1918 possible internal network
acl localnet src 172.16.0.0/12	# RFC1918 possible internal network
acl localnet src 192.168.0.0/16	# RFC1918 possible internal network
acl localnet src fc00::/7       # RFC 4193 local private network range
acl localnet src fe80::/10      # RFC 4291 link-local (directly plugged) machines
acl SSL_ports port 443
acl SSL_ports port 992
acl SSL_ports port 995
acl SSL_ports port 5555
acl SSL_ports port 80
acl Safe_ports port 80		# http
acl Safe_ports port 21		# ftp
acl Safe_ports port 443		# https
acl Safe_ports port 70		# gopher
acl Safe_ports port 210		# wais
acl Safe_ports port 1025-65535	# unregistered ports
acl Safe_ports port 280		# http-mgmt
acl Safe_ports port 488		# gss-http
acl Safe_ports port 591		# filemaker
acl Safe_ports port 777		# multiling http
acl Safe_ports port 992		# mail
acl Safe_ports port 995		# mail
acl CONNECT method CONNECT
acl vpnservers dst xxxxxxxxx
acl vpnservers dst 127.0.0.1
http_access deny !Safe_ports
http_access deny CONNECT !SSL_ports
http_access allow localhost manager
http_access allow localnet
http_access allow localhost
http_access allow vpnservers
http_access deny !vpnservers
http_access deny manager
http_access allow all
http_port 0.0.0.0:8080
http_port 0.0.0.0:8989
http_port 0.0.0.0:3128
http_port 0.0.0.0:3129
http_port 0.0.0.0:8000
END
sed -i $MYIP2 /etc/squid3/squid.conf;

# install vnstat & speedtest
apt-get -y install vnstat
apt install speedtest-cli -y

# install fail2ban
apt-get -y install fail2ban
service fail2ban restart

# install ddos dflate
apt-get -y install dnsutils dsniff grepcidr
wget https://github.com/jgmdev/ddos-deflate/archive/master.zip
unzip master.zip
cd ddos-deflate-master
./install.sh
rm -rf /root/master.zip

# install menu
cd
wget -O /usr/local/bin/menu "http://35.240.206.123:85/freevpnmenu.sh"
chmod +x /usr/local/bin/menu

# Restart Squid & OVPN
sudo systemctl start openvpn@server
systemctl enable openvpn@server
/etc/init.d/openvpn restart
service squid3 start
/etc/init.d/squid3 restart

# finilazing
rm *.sh *.zip
rm -rf config
rm -rf ~/.bash_history && history -c & history -w
	clear
	echo ""
	echo ""
	echo -e "${GREEN}Debian 8 Script By :${NC}"
	echo "___________      .__       .__  __           "
	echo "\__    ___/______|__| ____ |__|/  |_ ___.__. "
	echo "  |    |  \_  __ \  |/    \|  \   __<   |  | "
	echo "  |    |   |  | \/  |   |  \  ||  |  \___  | "
	echo "  |____|   |__|  |__|___|  /__||__|  / ____| "
	echo "                         \/          \/      "
	echo ""
	echo ""
	echo -e "${GREEN}OpenVPN & Squid Proxy Successfully Installed!${NC}"
	echo ""
	echo "Server IP : $MYIP"
	echo "OpenVPN Port : 443"
	echo "Squid Port : 3128, 3129, 8080, 8000"
	echo ""
	echo -e "OpenVPN Client Config Location @ ${CYAN}/root/client.ovpn${NC}"
	echo ""
	echo -e "Type ${CYAN}menu${NC} To See Command Lists."
	echo ""
	echo ""
exit

