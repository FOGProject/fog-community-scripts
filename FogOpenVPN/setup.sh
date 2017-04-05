#!/bin/bash



#Variables.
fogsettings="/opt/fog/.fogsettings"

rootCACertificate="/var/www/fog/management/other/ssl/srvpublic.crt"
rootCAKey="/opt/fog/snapins/ssl/CA/fogCA.key"
diffieHellmanParamaters="/opt/fog/snapins/ssl/CA/.fogCA.pem"
serverCertificate="/opt/fog/snapins/ssl/fog.csr"
serverKey="/opt/fog/snapins/ssl/.srvprivate.key"








#Check if FOG is installed.
if [[ ! -e $fogsettings ]]; then
    echo "Fog is not installed, please install it first."
    exit
fi

#source fogsettings.
source $fogsettings



#Check if this is the database host or not.
ip link show > /tmp/interfaces.txt
##Sed the 3rd, 5th, 7th, and 9th lines of output to variable.
interface1name="$(sed -n '3p' /tmp/interfaces.txt)"
interface2name="$(sed -n '5p' /tmp/interfaces.txt)"
interface3name="$(sed -n '7p' /tmp/interfaces.txt)"
interface4name="$(sed -n '9p' /tmp/interfaces.txt)"
##Get rid of temporary file.
rm -f /tmp/interfaces.txt
##Isolate the interface names using cut and send them to temporary files.
echo $interface1name | cut -d \: -f2 | cut -c2- > /tmp/interface1name.txt
echo $interface2name | cut -d \: -f2 | cut -c2- > /tmp/interface2name.txt
echo $interface3name | cut -d \: -f2 | cut -c2- > /tmp/interface3name.txt
echo $interface4name | cut -d \: -f2 | cut -c2- > /tmp/interface4name.txt
##Load the names from the temporary files.
interface1name="$(cat /tmp/interface1name.txt)"
interface2name="$(cat /tmp/interface2name.txt)"
interface3name="$(cat /tmp/interface3name.txt)"
interface4name="$(cat /tmp/interface4name.txt)"
##Get rid of the temporary files.
rm -f /tmp/interface1name.txt
rm -f /tmp/interface2name.txt
rm -f /tmp/interface3name.txt
rm -f /tmp/interface4name.txt
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

#Set initial vaules to false.
main="0"
node="0"


#See if any of the local IP addresses match the snmysqlhost field.
if [[ "$snmysqlhost" == "$interface1ip" ]]; then
    main="1"
elif [[ "$snmysqlhost" == "$interface2ip" ]]; then
    main="1"
elif [[ "$snmysqlhost" == "$interface3ip" ]]; then
    main="1"
elif [[ "$snmysqlhost" == "$interface4ip" ]]; then
    main="1"
elif [[ "$snmysqlhost" == "localhost" ]]; then
    main="1"
elif [[ "$snmysqlhost" == "127.0.0.1" ]]; then
    main="1"
else
    node="1"
fi



#If this is the main box, configure it as the OpenVPN Server.
if [[ "$main" == "1" ]]; then
    #Check for the CA, public and private files. If any are missing, error out and say FOG 1.3.0 or higher is required.
    if [[ ! -e /var/www/fog/management/other/ssl/srvpublic.crt ]]; then
        echo "Public certificate for FOG is not found."










    exit
fi




#If this is a storage node, configure it as an OpenVPN Client.
if [[ "$node" == "1" ]]; then












    exit
fi







