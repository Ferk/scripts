#!/bin/sh


sudo iptables -t nat -I PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 22 

