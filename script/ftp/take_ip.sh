#!/bin/sh

public_ip=""
while [[ -z $public_ip ]]; do
    public_ip=$(wget -qO- --header="Metadata:true" "http://169.254.169.254/metadata/loadbalancer?api-version=2020-10-01" | awk -F'[:,}]' '/frontendIpAddress/{print $4}' | tr -d '"')
    if [[ -n $public_ip ]]; then
        break
    fi
    public_ip=$(grep -m 1 -oE '^[0-9]{1,3}(\.[0-9]{1,3}){3}$' <<< "$(wget -T 10 -t 1 -4qO- "http://ip1.dynupdate.no-ip.com/" || curl -m 10 -4Ls "http://ip1.dynupdate.no-ip.com/")")
    if [[ -n $public_ip ]]; then
        break
    fi
    public_ip=$(wget -qO- ifconfig.co)
    if [[ -n $public_ip ]]; then
        break
    fi
    public_ip=$(host myip.opendns.com resolver1.opendns.com | grep -Po 'myip\.opendns\.com has address \K[\d.]+')
    if [[ -n $public_ip ]]; then
        break
    fi

    echo "Failed to get public IP address. Retrying in 1 seconds..."
    sleep 1
done

echo "
ForcePassiveIP $public_ip
" | tee -a /etc/pure-ftpd.conf
