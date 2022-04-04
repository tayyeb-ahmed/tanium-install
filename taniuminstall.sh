#!/bin/bash
#Get Linux OS, version, and platform'
SourceUri=$1
ServerName=$2
ServerPort=$3
LogVerbosityLevel=$4
ARCH=$(uname -i)

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
elif type lsb_release >/dev/null 2>&1; then
    OS=$(lsb_release -si)
    VER=$(lsb_release -sr)
elif [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VER=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
    OS=Debian
    VER=$(cat /etc/debian_version)
elif [ -f /etc/redhat-release ]; then
    OS=$(cat /etc/redhat-release | cut -d ' ' -f 1)
    VER=$(cat /etc/redhat-release | cut -d ' ' -f 3)
else
    OS=$(uname -s)
    VER=$(uname -r)
fi

if [[ "${OS}" =~ "Amazon" ]];then
    linuxOS=Amazon
    if [[ "${VER}" == "2" ]];then
        linuxOS="Amazon2"
        thisOS="Amazon2"
    else
        linuxOS="Amazon1"
        thisOS="Amazon1"
    fi
elif [[ "${OS}" =~ "CentOS" ]];then
    linuxOS=CentOS
    thisOS="${OS} ${VER:0:1}"
elif [[ "${OS}" =~ "Debian" ]];then
    linuxOS=Debian
    thisOS="${OS} ${VER:0:2}"
elif [[ "${OS}" =~ "Red" ]];then
    linuxOS=RedHat
elif [[ "${OS}" =~ "SLES" ]];then
    linuxOS=SLES
    thisOS="${OS} ${VER}"
elif [[ "${OS}" =~ "Ubuntu" ]];then
    linuxOS=Ubuntu
    thisOS="${OS} ${VER:0:2}"
else
    echo "OS not found"
    exit 1
fi

echo "Detected ${OS} ${VER}"

#Set Package Name
case $linuxOS in
"Amazon1")
    pkg="TaniumClient-7.2.314.3584-1.amzn2018.03.${ARCH}.rpm"
    svcStop="service TaniumClient stop"
    svcStart="service TaniumClient start"
;;
"Amazon2")
    pkg="TaniumClient-7.2.314.3584-1.amzn2.${ARCH}.rpm"
    svcStop="service TaniumClient stop"
    svcStart="service TaniumClient start"
;;
"CentOS")
    supported=("6","7","8")
    if [[ "${supported}" =~ "${VER:0:1}" ]];then
        pkg="TaniumClient-7.2.314.3584-1.rhe${VER:0:1}.${ARCH}.rpm"
    fi
    if [ "${VER:0:1}" == "5" ] || [ "${VER:0:1}" = "6" ];then
        svcStop="service TaniumClient stop"
        svcStart="service TaniumClient start"
    elif [ "${VER:0:1}" = "7" ] || [ "${VER:0:1}" = "7" ];then
        svcStop="systemctl stop taniumclient"
        svcStart="systemctl start taniumclient"
        svcEnable="systemctl enable taniumclient"
    fi
;;
"Debian")
    supported=("8","9")
    if [[ "${supported}" =~ "${VER:0:1}" ]];then
        ARCH=$(dpkg --print-architecture)
        pkg="taniumclient_7.2.314.3584-debian${VER:0:2}_${ARCH}.deb"
    fi
;;
"RedHat")
    supported=("5","6","7","8")
    if [[ "${supported}" =~ "${VER:0:1}" ]];then
        pkg="TaniumClient-7.2.314.3584-1.rhe${VER:0:1}.${ARCH}.rpm"
    fi
    if [ "${VER:0:1}" == "5" ] || [ "${VER:0:1}" = "6" ];then
        svcStop="service TaniumClient stop"
        svcStart="service TaniumClient start"
    elif [ "${VER:0:1}" = "7" ] || [ "${VER:0:1}" = "8" ];then
        svcStop="systemctl stop taniumclient"
        svcStart="systemctl start taniumclient"
        svcEnable="systemctl enable taniumclient"
    fi
;;
"SLES")
    supported=("11","12")
    if [[ "${supported}" =~ "${VER:0:2}" ]];then
        if [ "${VER:0:2}" == "12" ];then
            pkg="TaniumClient-7.2.314.3584-1.sle12.${ARCH}.rpm"
        elif [ "${VER:0:2}" == "11" ];then
            pkg="TaniumClient-7.2.314.3584-1.sle11.${ARCH}.rpm"
        fi
    fi
    svcStop="service TaniumClient stop"
    svcStart="service TaniumClient start"
;;
"Ubuntu")
    supported=("14","16","18")
    if [[ "${supported}" =~ "${VER:0:2}" ]];then
        ARCH=$(dpkg --print-architecture)
        pkg="taniumclient_7.2.314.3584-ubuntu${VER:0:2}_${ARCH}.deb"
    fi
    svcStop="systemctl stop taniumclient"
    svcStart="systemctl start taniumclient"
    svcEnable="systemctl enable taniumclient"
;;

esac

useradd -m -g 'aix' svc_tanium_000 -e -1
echo "Downloading and installing ${pkg}"

curl "${SourceUri}/${pkg}" -o "/tmp/${pkg}"
if [[ "${pkg}" =~ "deb" ]];then
    dpkg -i "/tmp/${pkg}"
elif [[ "${pkg}" =~ "rpm" ]];then
    rpm -i "/tmp/${pkg}"
fi

echo "Setting client configuration"
if [[ -d /opt/Tanium/TaniumClient ]];then
    service taniumclient stop
    cd /opt/Tanium/TaniumClient
    curl "${SourceUri}/tanium.pub" -o /opt/Tanium/TaniumClient/tanium.pub
    ./TaniumClient config set ServerNameList ${ServerName}
    ./TaniumClient config set ServerPort ${ServerPort}
    ./TaniumClient config set LogVerbosityLevel ${LogVerbosityLevel}

    service taniumclient start

    sleep 5

    ./TaniumClient config --version
    ./TaniumClient config get ServerNameList
    ./TaniumClient config get ServerPort
    ./TaniumClient config get LogVerbosityLevel
else
    echo "Tanium client install path not found"
    exit $?
fi

rm "/tmp/${pkg}" &> /dev/null
