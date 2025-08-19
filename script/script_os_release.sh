#!/bin/sh

LOG_FILE="/var/log/hook_update_os_release.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE" > /dev/null
}

#Check and Create log file
if [[ ! -f "$LOG_FILE" ]]; then
    touch "$LOG_FILE"
    chmod 666 "$LOG_FILE"
    log "Log file created: $LOG_FILE"
else
    log "Log file already exists: $LOG_FILE"
fi


if [ -e "/etc/os-release" ]; then
	log "File os-release exists"
	. /etc/os-release
	log "$VERSION_ID VERSION_ID in orignial Linux file"
else
	echo "File os-release don't exists"
	exit 1
fi

#Download packege for getting version
get_package() {
	PACKAGE_NAME="$1"
	wget https://dl-cdn.alpinelinux.org/alpine/latest-stable/main/x86_64/
	name_package=$(cat index.html | grep $PACKAGE_NAME | awk -F'"' '{print $2}')
	rm index.html
	wget https://dl-cdn.alpinelinux.org/alpine/latest-stable/main/x86_64/$name_package
	mkdir dir_$name_package
	tar xf $name_package -C dir_$name_package
}

#Take version
if [[ -z "$VERSION_ID" ]]; then
	get_package "alpine-release"
	VERSION_ID=$(cat dir_$name_package/etc/alpine-release)
	rm -rf name_package dir_$name_package
	log "Get version from alpine-release"
elif [[ -z "$VERSION_ID" ]]; then
	get_package "alpine-base-"
	VERSION_ID=$(grep "pkgver" dir_$name_package/.PKGINFO | cut -d'=' -f2 | tr -d ' ' | cut -d'-' -f1)
	rm -rf name_package dir_$name_package
	log "Get version from alpine-base"
fi

#Fix file os-release after update
{
    cat > /etc/os-release << EOF
NAME="SomeOS Linux"
ID=someos
VERSION_ID="$VERSION_ID"
VERSION="$VERSION_ID"
PRETTY_NAME="SomeOS v$VERSION_ID"
EOF
} 2>&1 | while IFS= read -r line; do
    log "os-release update: $line"
done

#Update version in other files
change_version() {
	sed -i "s/SomeOS version\s*.*/SomeOS version $VERSION_ID/g" /etc/someos-release
	sed -i "s/Welcome to SomeOS\s*.*/Welcome to SomeOS $VERSION_ID/g" /etc/issue
	sed -i "s/Welcome to SomeOS Linux\s*.*/Welcome to SomeOS $VERSION_ID \!/g" /etc/motd
}

list_files="/etc/someos-release /etc/issue /etc/motd"

for file in $list_files
do
	if [ -e "${file}" ]; then
		log "Found ${file}"
	else
		log "File ${file} don't exists"
		exit 1
	fi
done

change_version

#Check script work
if grep -q "SomeOS Linux" /etc/os-release; then
	log "Script completed successfully."
else
	log "Something didn't go right"
fi
