#!/bin/bash

# Reset
Color_Off='\033[0m'       # Text Reset

# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

# Bold
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BPurple='\033[1;35m'      # Purple
BCyan='\033[1;36m'        # Cyan
BWhite='\033[1;37m'       # White

# Underline
UBlack='\033[4;30m'       # Black
URed='\033[4;31m'         # Red
UGreen='\033[4;32m'       # Green
UYellow='\033[4;33m'      # Yellow
UBlue='\033[4;34m'        # Blue
UPurple='\033[4;35m'      # Purple
UCyan='\033[4;36m'        # Cyan
UWhite='\033[4;37m'       # White

# Background
On_Black='\033[40m'       # Black
On_Red='\033[41m'         # Red
On_Green='\033[42m'       # Green
On_Yellow='\033[43m'      # Yellow
On_Blue='\033[44m'        # Blue
On_Purple='\033[45m'      # Purple
On_Cyan='\033[46m'        # Cyan
On_White='\033[47m'       # White

# High Intensity
IBlack='\033[0;90m'       # Black
IRed='\033[0;91m'         # Red
IGreen='\033[0;92m'       # Green
IYellow='\033[0;93m'      # Yellow
IBlue='\033[0;94m'        # Blue
IPurple='\033[0;95m'      # Purple
ICyan='\033[0;96m'        # Cyan
IWhite='\033[0;97m'       # White

# Bold High Intensity
BIBlack='\033[1;90m'      # Black
BIRed='\033[1;91m'        # Red
BIGreen='\033[1;92m'      # Green
BIYellow='\033[1;93m'     # Yellow
BIBlue='\033[1;94m'       # Blue
BIPurple='\033[1;95m'     # Purple
BICyan='\033[1;96m'       # Cyan
BIWhite='\033[1;97m'      # White

# High Intensity backgrounds
On_IBlack='\033[0;100m'   # Black
On_IRed='\033[0;101m'     # Red
On_IGreen='\033[0;102m'   # Green
On_IYellow='\033[0;103m'  # Yellow
On_IBlue='\033[0;104m'    # Blue
On_IPurple='\033[0;105m'  # Purple
On_ICyan='\033[0;106m'    # Cyan
On_IWhite='\033[0;107m'   # White


PREFIX=${PWD##*/}
# Set up the topology

echo -e "\n${BGreen}== Spin up the Containers ==${Color_Off}\n"

docker-compose up -d
# Copy setup scripts to the emulators
docker cp ./setup2_hv1.sh ${PREFIX}-hv1-1:/
docker cp ./setup2_hv2.sh ${PREFIX}-hv2-1:/
# Execute the setup script on the emulators

echo -e "\n${BGreen}== Test & Turn up ==${Color_Off}\n"

docker exec ${PREFIX}-hv1-1 /setup2_hv1.sh
docker exec ${PREFIX}-hv2-1 /setup2_hv2.sh
# Start capturing packets on overlay and underlay network

docker exec -d ${PREFIX}-hv1-1 /bin/bash -c "tcpdump -i vm1a -w vm1_overlay.pcap"
docker exec -d ${PREFIX}-hv1-1 /bin/bash -c "tcpdump -i vm1b -w vm1_overlay2.pcap"
docker exec -d ${PREFIX}-hv2-1 /bin/bash -c "tcpdump -i vm2a -w vm2_overlay.pcap"
docker exec -d ${PREFIX}-hv2-1 /bin/bash -c "tcpdump -i vm2b -w vm2_overlay2.pcap"
docker exec -d ${PREFIX}-hv1-1 /bin/bash -c "tcpdump -i eth0 -w vm1_underlay.pcap"
docker exec -d ${PREFIX}-hv2-1 /bin/bash -c "tcpdump -i eth0 -w vm2_underlay.pcap"
# Ping from VM1 to VM2
echo -e "\n${IBlue}--- Performing PING tests for VXLAN ID 5000"
docker exec ${PREFIX}-hv1-1 /bin/bash -c "ping -I vm1a -c 1 192.168.1.2"
sleep 1
echo -e "\n${IPurple}--- Performing PING tests for VXLAN ID 5001"
docker exec ${PREFIX}-hv1-1 /bin/bash -c "ping -I vm1b -c 1 192.168.2.2"
sleep 1
echo -e "\n${IYellow}--- Performing PING tests for VXLAN ID 1001"
docker exec ${PREFIX}-hv1-1 /bin/bash -c "ping -I vm1c -c 1 192.168.3.2"
# Wait for the packets to be captured
sleep 2
echo -e "\n${Color_Off}done...\n"
# Kill the tcpdump process
docker exec ${PREFIX}-hv1-1 /bin/bash -c "pkill tcpdump"
docker exec ${PREFIX}-hv2-1 /bin/bash -c "pkill tcpdump"
# Collect *.pcap files
docker cp ${PREFIX}-hv1-1:/vm1_overlay.pcap .
docker cp ${PREFIX}-hv1-1:/vm1_overlay2.pcap .
docker cp ${PREFIX}-hv2-1:/vm2_overlay.pcap .
docker cp ${PREFIX}-hv2-1:/vm2_overlay2.pcap .
docker cp ${PREFIX}-hv1-1:/vm1_underlay.pcap .
docker cp ${PREFIX}-hv2-1:/vm2_underlay.pcap .
# Clean up
sleep 10
read -n 1 -p "Press enter to proceed w/ LAB shutdown..."

echo -e "\n${BRed}== Shutdown and remove the Containers. BYE ==${Color_Off}\n"

#echo "Press Enter to delete your Overlay network"
#read null
docker-compose kill
docker-compose rm -f

echo -e "\n${BGreen}== Script done. Check your capture files... ==${Color_Off}\n"

