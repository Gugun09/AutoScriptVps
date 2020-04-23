#!/bin/bash
# Script by : Gugun09
clear
echo 'echo -e "\e[0m                                    "
echo 'echo -e "\e[94m   ╔═╦═╦╗╔═╦══╗╔═╦═╦══╦╦╗╔═╦╦╦╦╦═╗	"
echo 'echo -e "\e[94m	║╚╣║║║║║║║║║║╚╣║╠╗╔╣║║╚╗║║║║║║║	"
echo 'echo -e "\e[94m	╠╗║╦║╚╣╦║║║║╠╗║╦║║║║║║╔╣║║║║║╦║	"
echo 'echo -e "\e[94m	╚═╩╩╩═╩╩╩╩╩╝╚═╩╩╝╚╝╚═╝╚═╩╩══╩╩╝	"
echo 'echo -e "\e[0m									"                                   
echo 'echo -e "\e[94m      [accounts/options/server]    "
echo 'echo -e "\e[0m                                    "
# Color
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# Menu
	clear
	echo ""
	echo -e "	${BLUE}-=[ LISTS OF COMMAND ]=-${NC}"
	echo ""
	echo -e "${BLUE}1]${NC} Accounts"
	echo -e "${BLUE}2]${NC} Options"
	echo -e "${BLUE}3]${NC} Server"
	echo -e "${BLUE}x]${NC} Exit"
	echo ""
	echo -e "${BLUE}>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<< ${NC}"
	
	
# vnstat meter
if [[ -e /etc/vnstat.conf ]]; then
	INTERFACE=`vnstat -m | head -n2 | awk '{print $1}'`
	TOTALBW=$(vnstat -i $INTERFACE --nick local | grep "total:" | awk '{print $8" "substr ($9, 1, 1)}')
fi

ON=0
OFF=0
while read ONOFF
do
	ACCOUNT="$(echo $ONOFF | cut -d: -f1)"
	ID="$(echo $ONOFF | grep -v nobody | cut -d: -f3)"
	ONLINE="$(cat /etc/openvpn/openvpn-status.log | grep -Eom 1 $ACCOUNT | grep -Eom 1 $ACCOUNT)"
	if [[ $ID -ge 1000 ]]; then
		if [[ -z $ONLINE ]]; then
			OFF=$((OFF+1))
		else
			ON=$((ON+1))
		fi
		fi
done < /etc/passwd

echo -e "TOTAL BANDWIDTH ${CYAN}$TOTALBW${NC}${CYAN}B${NC}"
echo -e "ONLINE CLIENT/S ${GREEN}$ON${NC}"

echo ""
echo -e "${BLUE}>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<< ${NC}"
	read -p "Select Menu From [1-3]: " MENU
	case $MENU in
		1)
		clear
		accounts
		exit
		;;
		2)
		clear
		options
		exit
		;;
		3)
		clear
		server
		exit
		;;
		x)
		clear
		exit
		;;
	esac
