#!/bin/bash

validip() {
    local ip=$1
    local stat=1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    echo $stat
}

getCidr() {
    local cidr
    cidr=$(ip -f inet -o addr | grep $1 | awk -F'[ /]+' '/global/ {print $5}' | head -n2 | tail -n1)
    echo $cidr
}
cidr2mask() {
    local i=""
    local mask=""
    local full_octets=$(($1/8))
    local partial_octet=$(($1%8))
    for ((i=0;i<4;i+=1)); do
        if [[ $i -lt $full_octets ]]; then
            mask+=255
        elif [[ $i -eq $full_octets ]]; then
            mask+=$((256 - 2**(8-$partial_octet)))
        else
            mask+=0
        fi
        test $i -lt 3 && mask+=.
    done
    echo $mask
}
mask2network() {
    OIFS=$IFS
    IFS='.'
    read -r i1 i2 i3 i4 <<< "$1"
    read -r m1 m2 m3 m4 <<< "$2"
    IFS=$OIFS
    printf "%d.%d.%d.%d\n"  "$((i1 & m1))" "$((i2 & m2))" "$((i3 & m3))" "$((i4 & m4))"
}
interface2broadcast() {
    local interface=$1
    if [[ -z $interface ]]; then
        echo "No interface passed"
        return 1
    fi
    echo $(ip -4 addr show | grep -w inet | grep $interface | awk '{print $4}')
}
subtract1fromAddress() {
    local ip=$1
    if [[ -z $ip ]]; then
        echo "No IP Passed"
        return 1
    fi
    if [[ ! $(validip $ip) -eq 0 ]]; then
        echo "Invalid IP Passed"
        return 1
    fi
    oIFS=$IFS
    IFS='.'
    read ip1 ip2 ip3 ip4 <<< "$ip"
    IFS=$oIFS
    if [[ $ip4 -gt 0 ]]; then
        let ip4-=1
    elif [[ $ip3 -gt 0 ]]; then
        let ip3-=1
        ip4=255
    elif [[ $ip2 -gt 0 ]]; then
        let ip2-=1
        ip3=255
        ip4=255
    elif [[ $ip1 -gt 0 ]]; then
        let ip1-=1
        ip2=255
        ip3=255
        ip4=255
    else
        echo "Invalid IP ranges were passed"
        echo ${ip1}.${ip2}.${ip3}.${ip4}
        return 2
    fi
    echo ${ip1}.${ip2}.${ip3}.${ip4}
}
addToAddress() {
    local ipaddress="$1"
    local increaseby=$2
    local maxOctetValue=256
    local octet1=""
    local octet2=""
    local octet3=""
    local octet4=""
    oIFS=$IFS
    IFS='.' read octet1 octet2 octet3 octet4 <<< "$ipaddress"
    IFS=$oIFS
    let octet4+=$increaseby
    if [[ $octet4 -lt $maxOctetValue && $octet4 -ge 0 ]]; then
        printf "%d.%d.%d.%d\n" $octet1 $octet2 $octet3 $octet4
        return 0
    fi
    numRollOver=$((octet4 / maxOctetValue))
    let octet4-=$((numRollOver * maxOctetValue))
    let octet3+=$numRollOver
    if [[ $octet3 -lt $maxOctetValue && $octet3 -ge 0 ]]; then
        printf "%d.%d.%d.%d\n" $octet1 $octet2 $octet3 $octet4
        return 0
    fi
    numRollOver=$((octet3 / maxOctetValue))
    let octet3-=$((numRollOver * maxOctetValue))
    let octet2+=$numRollOver
    if [[ $octet2 -lt $maxOctetValue && $octet2 -ge 0 ]]; then
        printf "%d.%d.%d.%d\n" $octet1 $octet2 $octet3 $octet4
        return 0
    fi
    numRollOver=$((octet2 / maxOctetValue))
    let octet2-=$((numRollOver * maxOctetValue))
    let octet1+=$numRollOver
    if [[ $octet1 -lt $maxOctetValue && $octet1 -ge 0 ]]; then
        printf "%d.%d.%d.%d\n" $octet1 $octet2 $octet3 $octet4
        return 0
    fi
    return 1
}




# Parameter 1 is the file to check for
checkFilePresence() {
    local file="$1"
    if [[ ! -f $file ]]; then
        echo "The file $file does not exist, exiting."
        exit 2
    fi
}


# Function checks if the variables needed are set
# Parameter 1 is the variable to test
# Parameter 2 is what the variable is testing for (msg string)
# Parameter 3 is the config file (msg string)
checkFogSettingVars() {
    local var="$1"
    local msg="$2"
    local cfg="$3"
    if [[ -z $var ]]; then
        echo "The $msg setting inside $cfg is not set, cannot continue, exiting."
        exit 3
    fi
}


## Function to find all interfaces, suggest each one, let user choose which. Supports up to 4 interfaces.
identifyInterfaces() {
    ##Send all ip information to temporary file.
    ip link show > $DIR/interfaces.txt
    ##Sed the 3rd, 5th, 7th, and 9th lines of output to variable.
    interface1name="$(sed -n '3p' $DIR/interfaces.txt)"
    interface2name="$(sed -n '5p' $DIR/interfaces.txt)"
    interface3name="$(sed -n '7p' $DIR/interfaces.txt)"
    interface4name="$(sed -n '9p' $DIR/interfaces.txt)"
    ##Get rid of temporary file.
    rm -f $DIR/interfaces.txt
    ##Isolate the interface names using cut and send them to temporary files.
    echo $interface1name | cut -d \: -f2 | cut -c2- > $DIR/interface1name.txt
    echo $interface2name | cut -d \: -f2 | cut -c2- > $DIR/interface2name.txt
    echo $interface3name | cut -d \: -f2 | cut -c2- > $DIR/interface3name.txt
    echo $interface4name | cut -d \: -f2 | cut -c2- > $DIR/interface4name.txt
    ##Load the names from the temporary files.
    interface1name="$(cat $DIR/interface1name.txt)"
    interface2name="$(cat $DIR/interface2name.txt)"
    interface3name="$(cat $DIR/interface3name.txt)"
    interface4name="$(cat $DIR/interface4name.txt)"
    ##Get rid of the temporary files.
    rm -f $DIR/interface1name.txt
    rm -f $DIR/interface2name.txt
    rm -f $DIR/interface3name.txt
    rm -f $DIR/interface4name.txt
    ##Parse IP addresses for each interface name.
    if [[ "$interface1name" != "" ]]; then
    interface1ip="$(/sbin/ip addr show | grep $interface1name | grep -o "inet [0-9]*\.[0-9]*\.[0-9]*\.[0-9]*" | grep -o "[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*")"
    fi
    if [[ "$interface2name" != "" ]]; then
    interface2ip="$(/sbin/ip addr show | grep $interface2name | grep -o "inet [0-9]*\.[0-9]*\.[0-9]*\.[0-9]*" | grep -o "[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*")"
    fi
    if [[ "$interface3name" != "" ]]; then
    interface3ip="$(/sbin/ip addr show | grep $interface3name | grep -o "inet [0-9]*\.[0-9]*\.[0-9]*\.[0-9]*" | grep -o "[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*")"
    fi
    if [[ "$interface4name" != "" ]]; then
    interface4ip="$(/sbin/ip addr show | grep $interface4name | grep -o "inet [0-9]*\.[0-9]*\.[0-9]*\.[0-9]*" | grep -o "[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*")"
    fi
    ##If there is no IP Address for the interfaces, assign local loopback. This means the interface doesn't exist.
    ##If only one interface has a legitimate address, don't even ask what interface to use.
    goodInterfaces="4"
    if [[ -z $interface1ip ]]; then
        interface1ip=127.0.0.1
        goodInterfaces=$(($goodInterfaces - 1))
    fi
    if [[ -z $interface2ip ]]; then 
        interface2ip=127.0.0.1
        goodInterfaces=$(($goodInterfaces - 1))
    fi
    if [[ -z $interface3ip ]]; then
        interface3ip=127.0.0.1
        goodInterfaces=$(($goodInterfaces - 1))
    fi
    if [[ -z $interface4ip ]]; then
        interface4ip=127.0.0.1
        goodInterfaces=$(($goodInterfaces - 1))
    fi
    ##Only do the menu stuff if there is more than one interface to pick from.
    if [[ "$goodInterfaces" -gt "1" ]]; then

        ##Build Menu
        MENU="\n\n    Please choose which interface to use.\n"
        if [[ "$interface1ip" != "127.0.0.1" ]]; then
            MENU="$MENU\n    1. $interface1name ($interface1ip)\n"
        fi
        if [[ "$interface2ip" != "127.0.0.1" ]]; then
            MENU="$MENU\n    2. $interface2name ($interface2ip)\n"
        fi
        if [[ "$interface3ip" != "127.0.0.1" ]]; then
            MENU="$MENU\n    3. $interface3name ($interface3ip)\n"
        fi
        if [[ "$interface4ip" != "127.0.0.1" ]]; then
            MENU="$MENU\n    4. $interface4name ($interface4ip)\n"
        fi

        ##Print menu.
        printf "$MENU\n"
        printf "    Selection:"
        read interfaceChoice # Assign user input to variable
        if [[ -z $interfaceChoice || ( $interfaceChoice != 1 && $interfaceChoice != 2 && $interfaceChoice != 3 && $interfaceChoice != 4 ) ]]; then
            echo Selection for interface was not valid, exiting.
            exit
        fi
        if [[ $interfaceChoice == 1 ]]; then
            newInterface="$interface1name"
            newIP="$interface1ip"
        elif [[ $interfaceChoice == 2 ]]; then
            newInterface="$interface2name"
            newIP="$interface2ip"
        elif [[ $interfaceChoice == 3 ]]; then
            newInterface="$interface3name"
            newIP="$interface3ip"
        elif [[ $interfaceChoice == 4 ]]; then
            newInterface="$interface4name"
            newIP="$interface4ip"
        fi
    #If there is only one valid interface, just use it and don't ask questions.
    elif [[ "$goodInterfaces" == "1" ]]; then
        if [[ "$interface1ip" != "127.0.0.1" ]]; then
            newIP="$interface1ip"
            newInterface="$interface1name"
            return
        fi
        if [[ "$interface2ip" != "127.0.0.1" ]]; then
            newIP="$interface2ip"
            newInterface="$interface2name"
            return
        fi
        if [[ "$interface3ip" != "127.0.0.1" ]]; then
            newIP="$interface3ip"
            newInterface="$interface3name"
            return
        fi
        if [[ "$interface4ip" != "127.0.0.1" ]]; then
            newIP="$interface4ip"
            newInterface="$interface4name"
            return
        fi
    else
        echo "No good interfaces found, exiting."
        exit
    fi
    return
}



## Update the IP in the database
updateIPinDB() {
    echo
    echo "Updating the IP Settings server-wide."
    statement1="UPDATE \`globalSettings\` SET \`settingValue\`='$newIP' WHERE \`settingKey\` IN ('FOG_TFTP_HOST','FOG_WOL_HOST','FOG_WEB_HOST');"
    statement2="UPDATE \`nfsGroupMembers\` SET \`ngmHostname\`='$newIP', \`ngmInterface\`='$newInterface' WHERE \`ngmMemberName\`='$storageNode' OR \`ngmHostname\`='$ipaddress';"
    sqlStatements="$statement1$statement2"

    # Builds proper SQL Statement and runs.
    # If no user defined, assume root
    [[ -z $snmysqluser ]] && $snmysqluser='root'
    # If no host defined, assume localhost/127.0.0.1
    [[ -z $snmysqlhost ]] && $snmysqlhost='127.0.0.1'
    # No password set, run statement without pass authentication
    if [[ -z $snmysqlpass ]]; then
        echo "A password was not set in $fogsettings for mysql use."
        mysql -u"$snmysqluser" -e "$sqlStatements" "$database"
    # Else run with password authentication
    else
        echo "A password was set in $fogsettings for mysql use."
        mysql -u"$snmysqluser" -p"${snmysqlpass}" -e "$sqlStatements" "$database"
    fi
}



## Update IP address in file default.ipxe
updateTFTP() {
    echo "Updating the IP in $tftpfile"
    sed -i "s|http://\([^/]\+\)/|http://$newIP/|" $tftpfile
    sed -i "s|http:///|http://$newIP/|" $tftpfile
}




## Update config.class.php
updateConfigClassPHP() {
    ##Set config file location and check
    configfile="${docroot}${webroot}lib/fog/config.class.php"
    checkFilePresence "$configfile"

    ## Backup config.class.php
    echo "Backing up $configfile"
    cp -f "$configfile" "${configfile}.old"

    ## Update IP in config.class.php
    echo "Updating the IP inside $configfile"
    sed -i "s|\".*\..*\..*\..*\"|\$_SERVER['SERVER_ADDR']|" $configfile
}

updateFogsettings() {
    ## Update .fogsettings IP ----#
    echo "Updating the fields inside of $fogsettings"
    sed -i "s|ipaddress='.*'|ipaddress='$newIP'|g" $fogsettings
    sed -i "s|interface='.*'|interface='$newInterface'|g" $fogsettings
    sed -i "s|submask='.*'|submask='$submask'|g" $fogsettings
    sed -i "s|routeraddress='.*'|routeraddress='$routeraddress'|g" $fogsettings
    sed -i "s|plainrouter='.*'|plainrouter='$routeraddress'|g" $fogsettings
    sed -i "s|dnsaddress='.*'|dnsaddress='$dnsaddress'|g" $fogsettings
    sed -i "s|startrange='.*'|startrange='$startrange'|g" $fogsettings
    sed -i "s|endrange='.*'|endrange='$endrange'|g" $fogsettings
}


suggestRoute() {
    local thisInterface=$1
    strSuggestedRoute=$(ip route | head -n1 | cut -d' ' -f3 | tr -d [:blank:])
    if [[ -z $strSuggestedRoute ]]; then
        strSuggestedRoute=$(route -n | grep "^.*U.*${thisInterface}$"  | head -n 1)
        strSuggestedRoute=$(echo ${strSuggestedRoute:16:16} | tr -d [:blank:])
    fi
    printf "$strSuggestedRoute"
}



suggestDNS() {
    strSuggestedDNS=""
    [[ -f /etc/resolv.conf ]] && strSuggestedDNS=$(cat /etc/resolv.conf | grep "nameserver" | head -n 1 | tr -d "nameserver" | tr -d [:blank:] | grep "^[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*$")
    [[ -z $strSuggestedDNS && -d /etc/NetworkManager/system-connections ]] && strSuggestedDNS=$(cat /etc/NetworkManager/system-connections/* | grep "dns" | head -n 1 | tr -d "dns=" | tr -d ";" | tr -d [:blank:] | grep "^[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*$")
    printf "$strSuggestedDNS"
}


configureDHCP() {

    if [[ "$bldhcp" == "Y" || "$bldhcp" == "1" ]]; then

        echo "Setting up and starting DHCP Server"

        dhcpconfig1="/etc/dhcp/dhcpd.conf" #standard
        dhcpconfig2="/etc/dhcp3/dhcpd.conf" #old ubuntu
        dhcpconfig3="/etc/dhcpd.conf" #old redhat & arch

        ## Copy, not move. This is important for later when writing the configuration. 
        [[ -f $dhcpconfig1 ]] && cp -f $dhcpconfig1 ${dhcpconfig1}.fogbackup
        [[ -f $dhcpconfig2 ]] && cp -f $dhcpconfig2 ${dhcpconfig2}.fogbackup
        [[ -f $dhcpconfig3 ]] && cp -f $dhcpconfig3 ${dhcpconfig3}.fogbackup
        [[ -z $bootfilename ]] && bootfilename="undionly.kkpxe"

	configFile=""

        configFile="${configFile}# DHCP Server Configuration file\n"
        configFile="${configFile}#see /usr/share/doc/dhcp*/dhcpd.conf.sample\n"
        configFile="${configFile}#\n"
        configFile="${configFile}# DHCP Configuration file generated by the fog-community-scripts updateIP utility\n"
        configFile="${configFile}# Author of utility: Wayne Workman\n"
        configFile="${configFile}#\n"
        configFile="${configFile}#Definition of PXE-specific options\n"
        configFile="${configFile}# Code 1: Multicast IP Address of bootfile\n"
        configFile="${configFile}# Code 2: UDP Port that client should monitor for MTFTP Responses\n"
        configFile="${configFile}# Code 3: UDP Port that MTFTP servers are using to listen for MTFTP requests\n"
        configFile="${configFile}# Code 4: Number of seconds a client must listen for activity before trying\n"
        configFile="${configFile}#         to start a new MTFTP transfer\n"
        configFile="${configFile}# Code 5: Number of seconds a client must listen before trying to restart\n"
        configFile="${configFile}#         a MTFTP transfer\n"
        configFile="${configFile}option space PXE;\n"
        configFile="${configFile}option PXE.mtftp-ip code 1 = ip-address;\n"
        configFile="${configFile}option PXE.mtftp-cport code 2 = unsigned integer 16;\n"
        configFile="${configFile}option PXE.mtftp-sport code 3 = unsigned integer 16;\n"
        configFile="${configFile}option PXE.mtftp-tmout code 4 = unsigned integer 8;\n"
        configFile="${configFile}option PXE.mtftp-delay code 5 = unsigned integer 8;\n"
        configFile="${configFile}option arch code 93 = unsigned integer 16;\n"
        configFile="${configFile}use-host-decl-names on;\n"
        configFile="${configFile}ddns-update-style interim;\n"
        configFile="${configFile}ignore client-updates;\n"
        configFile="${configFile}# Specify subnet of ether device you do NOT want service.\n"
        configFile="${configFile}# For systems with two or more ethernet devices.\n"
        configFile="${configFile}# subnet 136.165.0.0 netmask 255.255.0.0 {}\n"


        submask=$(cidr2mask $(getCidr $newInterface))
        network=$(mask2network $newIP $submask)
        startrange=$(addToAddress $network 10)
        endrange=$(subtract1fromAddress $(echo $(interface2broadcast $newInterface)))


        ## Include empty configurations for non-chosen networks on multi-homed FOG Server only if they don't match chosen network.
        if [[ "$interface1ip" != "127.0.0.1" && "$interface1ip" != "$newIP" ]]; then
            local altSubmask=$(cidr2mask $(getCidr $interface1name))
            local altNetwork=$(mask2network $interface1ip $submask)
            if [[ "$altSubmask" != "$submask" && "$altNetwork" != "$network" ]]; then
                configFile="${configFile}subnet $altNetwork netmask $altSubmask{}\n"
            fi
        fi
        if [[ "$interface2ip" != "127.0.0.1" && "$interface2ip" != "$newIP" ]]; then
            local altSubmask=$(cidr2mask $(getCidr $interface2name))
            local altNetwork=$(mask2network $interface2ip $submask)
            if [[ "$altSubmask" != "$submask" && "$altNetwork" != "$network" ]]; then
                configFile="${configFile}subnet $altNetwork netmask $altSubmask{}\n"
            fi
        fi
        if [[ "$interface3ip" != "127.0.0.1" && "$interface3ip" != "$newIP" ]]; then
            local altSubmask=$(cidr2mask $(getCidr $interface3name))
            local altNetwork=$(mask2network $interface3ip $submask)
            if [[ "$altSubmask" != "$submask" && "$altNetwork" != "$network" ]]; then
                configFile="${configFile}subnet $altNetwork netmask $altSubmask{}\n"
            fi
        fi
        if [[ "$interface4ip" != "127.0.0.1" && "$interface4ip" != "$newIP" ]]; then
            local altSubmask=$(cidr2mask $(getCidr $interface4name))
            local altNetwork=$(mask2network $interface4ip $submask)
            if [[ "$altSubmask" != "$submask" && "$altNetwork" != "$network" ]]; then
                configFile="${configFile}subnet $altNetwork netmask $altSubmask{}\n"
            fi
        fi


        ## Begin configuring the chosen subnet for DHCP.
        configFile="${configFile}subnet $network netmask $submask{\n"
        configFile="${configFile}    option subnet-mask $submask;\n"
        configFile="${configFile}    range dynamic-bootp $startrange $endrange;\n"
        configFile="${configFile}    default-lease-time 21600;\n"
        configFile="${configFile}    max-lease-time 43200;\n"
        configFile="${configFile}    next-server $newIP;\n"

        ## Use whatever router is currently configured.
        routeraddress=$(suggestRoute $newInterface)
        [[ ! $(validip $routeraddress) -eq 0 ]] && routeraddress=$(echo $routeraddress | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b")
        [[ $(validip $routeraddress) -eq 0 ]] && configFile="${configFile}    option routers $routeraddress;\n" || ( configFile="${configFile}    #option routers 0.0.0.0\n" && echo " !!! No router address found !!!" && routeraddress=" !!! No router address found !!!")

        ## Use whatever DNS is currently configured.
        dnsaddress=$(suggestDNS)
        [[ ! $(validip $dnsaddress) -eq 0 ]] && dnsaddress=$(echo $dnsaddress | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b")
        [[ $(validip $dnsaddress) -eq 0 ]] && configFile="${configFile}    option domain-name-servers $dnsaddress;\n" || ( configFile="${configFile}    #option routers 0.0.0.0\n" && echo " !!! No dns address found !!!" && dnsaddress=" !!! No dns address found !!!")


        ## Use /opt/fog/.fogsettings for the default legacy boot file.
        [[ -z "$bootfilename" ]] && bootfilename="undionly.kkpxe"

        configFile="${configFile}    class \"Legacy\" {\n"
        configFile="${configFile}        match if substring(option vendor-class-identifier, 0, 20) = \"PXEClient:Arch:00000\";\n"
        configFile="${configFile}        filename \"$bootfilename\";\n"
        configFile="${configFile}    }\n"
        configFile="${configFile}    class \"UEFI-32-2\" {\n"
        configFile="${configFile}        match if substring(option vendor-class-identifier, 0, 20) = \"PXEClient:Arch:00002\";\n"
        configFile="${configFile}        filename \"i386-efi/ipxe.efi\";\n"
        configFile="${configFile}    }\n"
        configFile="${configFile}    class \"UEFI-32-1\" {\n"
        configFile="${configFile}        match if substring(option vendor-class-identifier, 0, 20) = \"PXEClient:Arch:00006\";\n"
        configFile="${configFile}        filename \"i386-efi/ipxe.efi\";\n"
        configFile="${configFile}    }\n"
        configFile="${configFile}    class \"UEFI-64-1\" {\n"
        configFile="${configFile}        match if substring(option vendor-class-identifier, 0, 20) = \"PXEClient:Arch:00007\";\n"
        configFile="${configFile}        filename \"ipxe.efi\";\n"
        configFile="${configFile}    }\n"
        configFile="${configFile}    class \"UEFI-64-2\" {\n"
        configFile="${configFile}        match if substring(option vendor-class-identifier, 0, 20) = \"PXEClient:Arch:00008\";\n"
        configFile="${configFile}        filename \"ipxe.efi\";\n"
        configFile="${configFile}    }\n"
        configFile="${configFile}    class \"UEFI-64-3\" {\n"
        configFile="${configFile}        match if substring(option vendor-class-identifier, 0, 20) = \"PXEClient:Arch:00009\";\n"
        configFile="${configFile}        filename \"ipxe.efi\";\n"
        configFile="${configFile}    }\n"
        configFile="${configFile}    class \"SURFACE-PRO-4\" {\n"
        configFile="${configFile}        match if substring(option vendor-class-identifier, 0, 32) = \"PXEClient:Arch:00007:UNDI:003016\";\n"
        configFile="${configFile}        filename \"ipxe7156.efi\";\n"
        configFile="${configFile}    }\n"
        configFile="${configFile}    class \"Apple-Intel-Netboot\" {\n"
        configFile="${configFile}        match if substring(option vendor-class-identifier, 0, 14) = \"AAPLBSDPC/i386\";\n"
        configFile="${configFile}        option dhcp-parameter-request-list 1,3,17,43,60;\n"
        configFile="${configFile}        if (option dhcp-message-type = 8) {\n"
        configFile="${configFile}            option vendor-class-identifier \"AAPLBSDPC\";\n"
        configFile="${configFile}            if (substring(option vendor-encapsulated-options, 0, 3) = 01:01:01) {\n"
        configFile="${configFile}                # BSDP List\n"
        configFile="${configFile}                option vendor-encapsulated-options 01:01:01:04:02:80:00:07:04:81:00:05:2a:09:0D:81:00:05:2a:08:69:50:58:45:2d:46:4f:47;\n"
        configFile="${configFile}                filename \"ipxe.efi\";\n"
        configFile="${configFile}            }\n"
        configFile="${configFile}        }\n"
        configFile="${configFile}    }\n"
        configFile="${configFile}}\n"


	##Must handle other interfaces IF they are not on the same network as the chosen interface.



        [[ -f $dhcpconfig1 ]] && printf "$configFile" > $dhcpconfig1
        [[ -f $dhcpconfig2 ]] && printf "$configFile" > $dhcpconfig2
        [[ -f $dhcpconfig3 ]] && printf "$configFile" > $dhcpconfig3


    fi
    if [[ "$dodhcp" == "Y" || "$dodhcp" == "1" ]]; then

        echo "Attempting to start DHCP service..."

        ## Don't worry about what's the proper way to restart DHCP, just try all of them.
        systemctl enable $dhcpd > /dev/null 2>&1
        systemctl restart $dhcpd > /dev/null 2>&1
        systemctl status $dhcpd > /dev/null 2>&1
        if [[ "$?" == "0" ]]; then
            #echo "DHCP is running."
            local dhcpRunning="yes"
        fi
        
        service $dhcpd enable > /dev/null 2>&1
        service $dhcpd restart > /dev/null 2>&1
        service $dhcpd status > /dev/null 2>&1
        if [[ "$?" == "0" ]]; then
            #echo "DHCP is running."
            local dhcpRunning="yes"
        fi


        sysv-rc-conf $dhcpd on > /dev/null 2>&1
        /etc/init.d/$dhcpd stop > /dev/null 2>&1
        sleep 2
        /etc/init.d/$dhcpd start > /dev/null 2>&1
        sleep 2
        /etc/init.d/$dhcpd status > /dev/null 2>&1
        if [[ "$?" == "0" ]]; then
            #echo "DHCP is running."
            local dhcpRunning="yes"
        fi

        if [[ "$dhcpRunning" != "yes" ]]; then
            echo "!--- DHCP status is unknown, please check ---!"
        else
            echo "DHCP looks good."
        fi


    fi
}
