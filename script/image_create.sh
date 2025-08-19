#!/bin/bash

read -p "Type image name for creating: " image_name
echo "Your image name: Yvital-"$image_name"-img "
echo ""

read -p "Chose your directory (* = 1) or (* = 2) or (* = 3): " directory

case $directory in 
	"1")
	directory_type="link$blob"
	subscrip="*"
	region="*"
	;;
	"2")
	directory_type="link$blob"
	subscrip="*"
	region="*"
	;;
	"3")
	directory_type="link$blob"
	subscrip="*"
	region="*"
	;;	
	*)
	echo "You chose something wrong, try again"
	exit 1
esac

resGroup="*"

read -p "Blob name: " blob

echo ""

full_link_blob=$directory_type$blob
echo "Your blob: $full_link_blob "

read -p "Chose OS type (Linux = 1 or Windows = 2): " os_number

case $os_number in 
	"1")
	os_type="Linux"
	;;
	"2")
	os_type="Windows"
	;;
	*)
	echo "You chose something wrong, try again"
	exit 1
esac

echo "System for your image: $os_type "
echo ""
echo "Check your configuration if wrong push Ctrl+C"

sleep 10

image_name=$(az image create --name Yvital-"$image_name"-img \
				--resource-group $resGroup \
				--source $full_link_blob \
				--hyper-v-generation V2 \
				--storage-sku Standard_LRS \
				--subscription $subscrip \
				--os-type $os_type \
				--query name \
				--location $region \
				-o tsv)
echo "Your image name: $image_name "
