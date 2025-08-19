#!/bin/bash


read -p "Type disk name from packer: " disk_name

read -p "Type destination blob name (without suffix - *): " blob_name
echo "Blob name: "$blob_name"*.vhd"

blob_name_with_pref="$blob_name"*.vhd

read -p "Chose your directory (* = 1) or (* = 2) or (* = 3): " directory

case $directory in 
	"1")
	storageAcc="*"
	containerName="*"
	subscrip="*"
	location="*"
	;;
	"2")
	storageAcc="*"
	containerName="*"
	subscrip="*"
	location="*"
	;;
	"3")
	storageAcc="*"
	containerName="*"
	subscrip="*"
	location="*"
	;;
	*)
	echo "You chose something wrong, try again"
	exit 1
esac

read -p "Choose your group (* = 1) or (* = 2): " group

case $group in 
	"1")
	resGroup=*
	;;
	"2")
	resGroup=*
	;;
	*)
	echo "You chose something wrong, try again"
	exit 1
esac

sleep 10


nameSnapshot="$blob_name"-snapshot

diskName="$blob_name"-FOR-BLOB-disk

az snapshot create \
  --resource-group $resGroup \
  --name $nameSnapshot \
  --location $location \
  --subscription $subscrip \
  --source $disk_name


if [ $? -ne 0 ]; then
  echo "Failed to create snapshot"
  exit 1
fi

az disk create \
  --resource-group $resGroup \
  --name $diskName \
  --location $location \
  --subscription $subscrip \
  --source $nameSnapshot


if [ $? -ne 0 ]; then
  echo "Failed to create disk from snapshot"
  exit 1
fi

urlForExport=$(az disk grant-access \
  --resource-group $resGroup \
  --name $diskName \
  --subscription $subscrip \
  --duration-in-seconds 3600 \
  --access-level Read \
  --output tsv 2> /dev/null)


if [ $? -ne 0 ]; then
  echo "Failed to grant access to the disk"
  exit 1
fi

echo $urlForExport


az storage blob copy start \
  --account-name  $storageAcc \
  --destination-container $containerName \
  --subscription $subscrip \
  --destination-blob $blob_name_with_pref \
  --source-uri $urlForExport 


if [ $? -ne 0 ]; then
  echo "Failed to start blob copy"
  echo "revoke access on disk"
  az disk revoke-access -n $diskName -g $resGroup --subscription $subscrip
  exit 1
fi


key=$(az storage account keys list --resource-group store_group --account-name $storageAcc --subscription $subscrip --query '[0].value' -o tsv 2> /dev/null )


while true;
do
	sta=$(az storage blob show --account-name $storageAcc --account-key $key -c $containerName --subscription $subscrip -n $blob_name_with_pref --query properties.copy.status -o tsv 2> /dev/null )
	if [ "$sta" = "success" ]; then
	echo -e "\rCOPY DONE"
	break
	elif [ "$sta" = "failed" ]; then
	echo -e "\rCOPY FAILED"
	break
	fi
    echo -ne "\rWAIT COPY STATUS $sta \c"
    sleep 1
done

echo ""
echo "revoke access on disk"
az disk revoke-access -n $diskName -g $resGroup --subscription $subscrip

echo ""
echo "Blob name: "$blob_name"_vm_for_azuremarket.vhd"

