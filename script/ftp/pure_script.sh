#!/bin/bash

# Get OS name
if [[ -e /etc/os-release ]]; then
	if grep -q "Alpine Linux" /etc/os-release || grep -q "SomeOS" /etc/os-release; then
			OS=$(grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
			VERSION=$(grep '^VERSION_ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
			DISTRO=$(awk -F= '/^NAME/{print $2}' /etc/os-release | tr -d '"')
			os_version=$(grep "VERSION_ID=" /etc/os-release | cut -d'=' -f2 | tr -d '"' | cut -d"." -f1)
		else
			OS=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')
			VERSION=$(grep -oP '(?<=^VERSION_ID=).+' /etc/os-release | tr -d '"')
			DISTRO=$(awk -F= '/^NAME/{print $2}' /etc/os-release | tr -d '"')
			os_version=$(grep "VERSION_ID=" /etc/os-release | cut -d'=' -f2 | tr -d '"' | cut -d"." -f1)
		fi
elif [[ -e /etc/redhat-release ]]; then
    DISTRO=$(awk '{print $1}' /etc/redhat-release)
    VERSION=$(awk '{print $3}' /etc/redhat-release)
    os_version=$(echo "$VERSION" | cut -d'.' -f1)
    case $DISTRO in
        "CentOS") OS="centos" ;;
        "Red"|"Rocky"|"AlmaLinux") OS="redhat" ;;
        "Oracle") OS="oracle" ;;
    esac
elif [[ -e /etc/SuSE-release ]]; then
    DISTRO=$(awk '/VERSION/{print $3}' /etc/SuSE-release)
    OS=$(awk '/ID/{print $3}' /etc/SuSE-release)
    os_version=$(echo "$DISTRO" | cut -d'.' -f1)
elif [[ -e /etc/lsb-release ]]; then
    OS=$(grep -oP '(?<=^DISTRIB_ID=).+' /etc/lsb-release | tr -d '"')
    VERSION=$(grep -oP '(?<=^DISTRIB_RELEASE=).+' /etc/lsb-release | tr -d '"')
    DISTRO="ubuntu"
    os_version=$(echo "$VERSION" | cut -d'.' -f1)
elif [[ -e /etc/system-release ]]; then
    if grep -q "Amazon Linux" /etc/system-release; then
        OS="amzn"
        VERSION="2"  # Assuming it's Amazon Linux 2
        DISTRO="Amazon Linux"
    fi
fi

echo $OS


manager=""
flag=""

if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]
then
        manager="apt"
        flag="-y"
elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
        manager="dnf"
        flag="-y"
elif [ "$OS" = "sles" ]; then
        sleep 50
        manager="zypper"
        flag="-n"
        sudo $manager $flag refresh
fi



#Install dependencies
if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]
then
        sudo $manager install $flag wget make gcc libssl-dev
elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
		sudo mkdir /etc/ssl/private
        sudo $manager install $flag wget make gcc openssl-devel
elif [ "$OS" = "alpine" ] || [ "$OS" = "carpaos" ]; then
		doas apk update
		doas apk add make grep wget gcc openssl-dev grep build-base curl tar curl
fi



#Install pureFTPd
latestVersion=$(curl -s https://download.pureftpd.org/pub/pure-ftpd/releases/ | grep -oP 'pure-ftpd-\d+\.\d+\.\d+\.tar\.gz' | sort -V | tail -1)
wget https://download.pureftpd.org/pub/pure-ftpd/releases/$latestVersion
tar -xf $latestVersion
rm -rf $latestVersion
mv pure-ftpd* pure-ftpd
cd pure-ftpd
echo "------------CONFIGURE"
./configure --with-tls --with-puredb --with-altlog
make
echo "------------DO MAKE"
sudo make install



#Create virtual user
echo "_______CREATE USER"
sudo mkdir /home/ftpuser
sudo groupadd ftpgroup
sudo useradd -g ftpgroup -d /home/ftpuser -s /sbin/nologin ftpuser
sudo chown -R ftpuser:ftpgroup /home/ftpuser/
sudo chmod -R 755 /home/ftpuser/
echo "--------USE PURE-PW"
sudo touch /etc/pureftpd.passwd
sudo /usr/local/bin/pure-pw mkdb




#Conf pure-ftpd.conf
echo "ChrootEveryone               yes
BrokenClientsCompatibility   no
MaxClientsNumber             50
Daemonize                    yes
MaxClientsPerIP              8
VerboseLog                   no
AltLog                       clf:/var/log/pureftpd.log
DisplayDotFiles              yes
AnonymousOnly                no
NoAnonymous                  no
SyslogFacility               ftp
DontResolve                  yes
MaxIdleTime                  15
PureDB                       /etc/pureftpd.pdb
LimitRecursion               10000 8
AnonymousCanCreateDirs       no
MaxLoad                      4
PassivePortRange             30000 50000
AntiWarez                    yes
Umask                        133:022
CreateHomeDir                yes
MinUID                       100
AllowUserFXP                 no
AllowAnonymousFXP            no
ProhibitDotFilesWrite        no
ProhibitDotFilesRead         no
AutoRename                   no
AnonymousCantUpload          no
MaxDiskUsage                   99
CustomerProof                yes
CertFile                     /etc/ssl/private/pure-ftpd.pem
TLS 2
TLSCipherSuite               HIGH:!aNULL:!MD5:!SSLv3:!TLSv1:!TLSv1.1:@STRENGTH" | sudo tee /etc/pure-ftpd.conf

doas rm /var/run
doas mkdir -p /var/run
doas chown root:root /var/run
doas chmod 755 /var/run

#Create service
case $OS in
	"alpine" | "carpaos")
sudo tee /etc/init.d/pure-ftpd << 'EOF'
#!/sbin/openrc-run

name="pure-ftpd"
description="Pure-FTPd FTP server"
command="/usr/local/sbin/pure-ftpd"
command_args="/etc/pure-ftpd.conf"
command_background="yes"
pidfile="/run/pure-ftpd.pid"

depend() {
    need net
    after firewall
}

stop() {
    ebegin "Stopping ${name}"
    start-stop-daemon --stop --pidfile "${pidfile}" --name "${name##*/}"
    eend $?
}
EOF
	;;
	*)
	echo "[Unit]
	Description=Pure-FTPd FTP server
	After=network.target
	Requires=network.target

	[Service]
	Type=forking
	ExecStart=/usr/local/sbin/pure-ftpd /etc/pure-ftpd.conf
	ExecStop=/usr/bin/pkill -x pure-ftpd
	Restart=on-failure
	RestartSec=5
	User=root


	[Install]
	WantedBy=multi-user.target" | sudo tee /etc/systemd/system/pure-ftpd.service
;;
esac


case $OS in
	"alpine" | "carpaos")
	doas chmod +x /etc/init.d/pure-ftpd
	doas rc-update add pure-ftpd default
	#doas rc-service pure-ftpd status
	;;
	*)
	sudo systemctl daemon-reload
	sudo systemctl enable pure-ftpd.service
	;;
esac




