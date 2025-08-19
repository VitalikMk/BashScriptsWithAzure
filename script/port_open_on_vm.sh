#!/bin/bash

read -p "Type vm name: " vm_name

read -p "Write number port for opening(80; 80-444)" port_num

read -p "Chose your directory (* = 1) or (* = 2): " directory

case $directory in 
	"1")
	subscrip="*"
	;;
	"2")
	subscrip="*"
	;;
	*)
	echo "You chose something wrong, try again"
	exit 1
esac

min=1500
max=4000 
prior=$(($RANDOM%($max-$min+1)+$min))

az vm open-port -g store_group -n $vm_name --port $port_num --priority $prior --subscription $subscrip
