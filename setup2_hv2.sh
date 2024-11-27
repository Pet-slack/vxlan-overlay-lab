#!/bin/bash

# Add a switch br0
ovs-vsctl add-br br0
# Add a port vm2 to br0
ovs-vsctl add-port br0 vm2a -- set interface vm2a type=internal
ovs-vsctl add-port br0 vm2b -- set interface vm2b type=internal
ovs-vsctl add-port br0 vm2c -- set interface vm2c type=internal
# Set the vm2's MAC address
ifconfig vm2a hw ether 00:00:00:00:0a:02
ifconfig vm2b hw ether 00:00:00:00:0b:02
ifconfig vm2c hw ether 00:00:00:00:0c:02
# Set the vm2's IP address
ifconfig vm2a 192.168.1.2 netmask 255.255.255.0 up
ifconfig vm2b 192.168.2.2 netmask 255.255.255.0 up
ifconfig vm2c 192.168.3.2 netmask 255.255.255.0 up
# Add br0 to vtep database
vtep-ctl add-ps br0
# Set the underlay tunnel IP to be eth0's IP
vtep-ctl set Physical_Switch br0 tunnel_ips=10.1.0.1
# Start VTEP emulator
/usr/local/share/openvswitch/scripts/ovs-vtep --log-file --pidfile --detach br0
sleep 1
# Add Logical switch ls0
vtep-ctl add-ls ls0
vtep-ctl add-ls ls1
vtep-ctl add-ls ls2
# Set VXLAN ID of ls0 to 5000
vtep-ctl set Logical_Switch ls0 tunnel_key=5000
vtep-ctl set Logical_Switch ls1 tunnel_key=5001
vtep-ctl set Logical_Switch ls2 tunnel_key=1001
# Binding ls0 to port vm2 with VLAN 0
vtep-ctl bind-ls br0 vm2a 0 ls0
vtep-ctl bind-ls br0 vm2b 0 ls1
vtep-ctl bind-ls br0 vm2c 0 ls2
# Add remote VM2's MAC address and physical locator
vtep-ctl add-ucast-remote ls0 00:00:00:00:0a:01 10.0.0.1
vtep-ctl add-ucast-remote ls1 00:00:00:00:0b:01 10.0.0.1
vtep-ctl add-ucast-remote ls2 00:00:00:00:0c:01 10.0.0.1
