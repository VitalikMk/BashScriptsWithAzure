#!/bin/bash

read -p "Type your name project for VM(Yvital-NAME (7 chars max)) : " vm_name
read -p "Type image name: " image_name

read -p "Chose your directory (* = 1) or (* = 2) or (* = 3): " directory

case $directory in 
	"1")
	subscrip="*"
	location="*"
	;;
	"2")
	subscrip="*"
	location="*"
	;;
	"3")
	subscrip="*"
	location="*"
	;;
	*)
	echo "You chose something wrong, try again"
	exit 1
esac

echo "You entered: Yvital-$vm_name"
# Resource group and location
resourceGroup=*


# Network configuration
vnetName=Yvital-vnet-"$vm_name"
subnetName=Yvital-subnet-"$vm_name"
vnetAddressPrefix=10.0.0.0/16
subnetAddressPrefix=10.0.0.0/24

# Create virtual network
az network vnet create \
    --name $vnetName \
    --resource-group $resourceGroup \
    --location $location \
    --address-prefixes $vnetAddressPrefix \
    --subnet-name $subnetName \
    --subscription $subscrip \
    --subnet-prefixes $subnetAddressPrefix

# VM configuration
vmName=Yvital-"$vm_name"
adminUsername="*"
adminPassword="*" 

# Create VM
az vm create \
    --resource-group $resourceGroup \
    --name $vmName \
    --image $image_name \
    --vnet-name $vnetName \
    --subnet $subnetName \
    --size Standard_B1ms \
    --location $location \
    --authentication-type password \
    --admin-username $adminUsername \
    --admin-password $adminPassword \
    --storage-sku Standard_LRS \
    --subscription $subscrip \
    --output json \
    --verbose

# Check the result
if [ $? -eq 0 ]; then
    echo "VM created successfully."
    # Get the public IP address
    publicIP=$(az vm show -d -g $resourceGroup --subscription $subscrip -n $vmName --query publicIps -o tsv)
    echo "VM public IP: $publicIP"
else
    echo "Failed to create VM."
    exit 1
fi
