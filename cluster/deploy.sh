#!/bin/bash
# set -x

### API Credentials
# API_USER="PLACE YOUR GLESYS PROJECT ID HERE"   
# API_KEY="PLACE YOUR API KEY HERE" 




#Servers Creation Variables:
web_num=2 # HOW MANY WEB SERVERS DO YOU WANT
DATACENTER=Falkenberg
PLATFORM=OpenVZ
TEMPLATE="Debian 9 64-bit"	#DONT CHANGE THIS
DISKSIZE=20
MEMORYSIZE=2048
CPUCORES=2
ROOTPASS=`pwgen -Bs 15 1`	# YOU CAN WRITE YOUR OWN PASSWORD IF YOU LIKE  # ROOTPASS="THISISPASSWORD"
############################

if [ -z $2 ]; then
        echo "syntax is: $0 user domain.com"
        exit
fi

DEPS=`whereis ansible-playbook`
if [ "$?" -ne 0 ]; then
        echo "ansible finns ej, kolla README"
        exit 0
fi
#
FTP_USERNAME=$1
#DOMAIN
FQDN=$2
# Validate provided FQDN
if [[ $FQDN =~ ^[A-Za-z0-9]+.+\..+ ]]; then
        HOSTNAME=`echo "$FQDN" | cut -f1 -d.`
        DOMAIN=`expr "$FQDN" | cut -f2- -d.`
else
        echo "not a correct FQDN (ie. domain.com)"
        exit 1
fi
### WordPress info. Feel free to edite!
wp_user="$FTP_USERNAME"
wp_email="$FTP_USERNAME@$FQDN"
wp_title="DEFAULT TITLE"



#Functions
function validate_xml {
#Check if API call got status 200 (OK)
STATUSCODE=`xmlstarlet sel -t -v "/response/status/code" server.xml`
if [ "$STATUSCODE" -ne 200 ]; then
        ERRORCODE=`xmlstarlet sel -t -v "/response/status/text" server.xml`
        echo "Error: $ERRORCODE"
        exit 1
fi
}
function wait_1 {
secs=$((1 * 60))
while [ $secs -gt 0 ]; do
   minutes=$(($secs / 60))
   secs_2=$(($secs - $minutes * 60))
   echo -ne "waiting 1 minute : $minutes:$secs_2 \033[0K\r"
   sleep 1
   : $((secs--))
done
}

API_USER=`echo $API_USER | sed "s# ##g"`
API_KEY=`echo $API_KEY | sed "s# ##g"`
if  [[ -z $API_USER ]]; then
echo "GleSYS project ID not defined"
echo "Please read readme.txt for more info."
exit 1
fi



#Check if API Credentials are valid 
API_CHECK_CODE=`curl -sS -X POST --basic -u $API_USER:$API_KEY https://api.glesys.com/api/serviceinfo/ | xmlstarlet sel -t -v "/response/status/code"`
if [ "$API_CHECK_CODE" -ne 200 ]; then
        ERRORCODE=`curl -sS -X POST --basic -u $API_USER:$API_KEY https://api.glesys.com/api/serviceinfo/ |xmlstarlet sel -t -v "/response/status/text" `
        echo "Error: $ERRORCODE"
        exit 1
fi
echo "API Credentials are OK."


#Check if API Credentials has access to servers
API_CHECK_CODE=`curl -sS -X POST --basic -u $API_USER:$API_KEY https://api.glesys.com/server/list/ | xmlstarlet sel -t -v "/response/status/code"`
if [ "$API_CHECK_CODE" -ne 200 ]; then
        ERRORCODE=`curl -sS -X POST --basic -u $API_USER:$API_KEY https://api.glesys.com/server/list/ |xmlstarlet sel -t -v "/response/status/text" `
        echo "API has no access to the serverss in this project"
        exit 1
fi
echo "API Access to the servers are OK."

#Check if API Credentials has access to ip
API_CHECK_CODE=`curl -sS -X POST --basic -u $API_USER:$API_KEY https://api.glesys.com/ip/listown/ | xmlstarlet sel -t -v "/response/status/code"`
if [ "$API_CHECK_CODE" -ne 200 ]; then
        ERRORCODE=`curl -sS -X POST --basic -u $API_USER:$API_KEY https://api.glesys.com/ip/listown/ |xmlstarlet sel -t -v "/response/status/text" `
        echo "API has no access to the IPs in this project"
        exit 1
fi
echo "API Access to IPs are OK."

#Check if API Credentials has access to loadbalancer
API_CHECK_CODE=`curl -sS -X POST --basic -u $API_USER:$API_KEY https://api.glesys.com/loadbalancer/list/ | xmlstarlet sel -t -v "/response/status/code"`
if [ "$API_CHECK_CODE" -ne 200 ]; then
        ERRORCODE=`curl -sS -X POST --basic -u $API_USER:$API_KEY https://api.glesys.com/loadbalancer/list/ |xmlstarlet sel -t -v "/response/status/text" `
        echo "API has no access to the loadbalancer in this project"
        exit 1
fi
echo "API Access to loadbalancer are OK."

#Check if API Credentials has access to filestorage
API_CHECK_CODE=`curl -sS -X POST --basic -u $API_USER:$API_KEY https://api.glesys.com/filestorage/listvolumes/ | xmlstarlet sel -t -v "/response/status/code"`
if [ "$API_CHECK_CODE" -ne 200 ]; then
        ERRORCODE=`curl -sS -X POST --basic -u $API_USER:$API_KEY https://api.glesys.com/filestorage/listvolumes/ |xmlstarlet sel -t -v "/response/status/text" `
        echo "API has no access to the filestorage in this project"
        exit 1
fi
echo "API Access to filestorage are OK."


##############################################################################################################



re='^[0-9]+$'
if ! [[ $web_num =~ $re ]] ; then
   echo "error: Not a number" >&2; exit 1
fi
if [[ $web_num == 0 || $web_num -gt 10 ]] ; then
   echo "The nummer is too high or 0. (Max 10 webservers)" >&2; exit 1
fi

# checking if there are servers with the same hostname.
curl -sS -X POST --basic -u $API_USER:$API_KEY https://api.glesys.com/server/list/ | grep ">db.$FQDN<" >  /dev/null 2>&1
if [[ $? -eq 0 ]] ; then
   echo "Can not proceed, Error: There is already a server with hostname ( db.$FQDN ) " >&2; exit 1
fi

while_var1=$web_num
while [ $while_var1 -gt 0 ] 
do
while_var2=$(( $web_num - $while_var1 ))
curl -sS -X POST --basic -u $API_USER:$API_KEY https://api.glesys.com/server/list/ | grep ">web$(( $while_var2 + 1 )).$FQDN<" >  /dev/null 2>&1
if [[ $? -eq 0 ]] ; then
   echo "Can not proceed, Error: There is already a server with hostname ( web$(( $while_var2 + 1 )).$FQDN ) " >&2; exit 1
fi
while_var1=$[$while_var1-1]
done

# checking if there is a filestorage with the same name¨.

curl -sS -X POST --basic -u $API_USER:$API_KEY https://api.glesys.com/filestorage/listvolumes | grep ">fs-$FQDN<" >  /dev/null 2>&1
if [[ $? -eq 0 ]] ; then
   echo "Can not proceed, Error: There is already a filestorage with the name ( fs-$FQDN )" >&2; exit 1
fi
# checking if there is a load balancer with the same name¨.

curl -sS -X POST --basic -u $API_USER:$API_KEY https://api.glesys.com/loadbalancer/list/ | grep ">lb-$FQDN<" >  /dev/null 2>&1
if [[ $? -eq 0 ]] ; then
   echo "Can not proceed, Error: There is already a load balancer with the name ( lb-$FQDN )" >&2; exit 1
fi



# Removing old services_details
echo “Removing old services_details”
if [ -d services_details ]; then
       rm services_details/*
fi;

#if it does not exist, create it
mkdir -p services_details

# creating File-storage
echo "creating File-storage ........."
curl -sS -X POST --basic -u $API_USER:$API_KEY --data-urlencode "datacenter=$DATACENTER" --data-urlencode "name=fs-$FQDN" --data-urlencode "planid=3b2064e5-a216-44d6-abb9-af4d501cb52c" https://api.glesys.com/filestorage/createvolume/ > services_details/filestorage.xml


# creating Load Balancer 
echo "creating Load Balancer ........."
curl -sS -X POST --basic -u $API_USER:$API_KEY --data-urlencode "name=lb-$FQDN" --data-urlencode "ip=any" --data-urlencode "datacenter=$DATACENTER" https://api.glesys.com/loadbalancer/create/ > services_details/lb.xml

# creating Database server.
echo "creating Database server ........."
curl -sS -X POST --basic -u $API_USER:$API_KEY --data-urlencode "datacenter=Falkenberg" --data-urlencode "platform=OpenVZ" --data-urlencode "hostname=db.$FQDN" --data-urlencode "rootpassword=$ROOTPASS" --data-urlencode "templatename=$TEMPLATE" --data-urlencode "disksize=$DISKSIZE" --data-urlencode "memorysize=$MEMORYSIZE" --data-urlencode "cpucores=$CPUCORES" https://api.glesys.com/server/create/ > services_details/db_server.xml


# creating web servers.
while_var1=$web_num
while [ $while_var1 -gt 0 ] 
do
while_var2=$(( $web_num - $while_var1 ))
echo "creating web server $(( $while_var2 + 1 )) ........."
curl -sS -X POST --basic -u $API_USER:$API_KEY --data-urlencode "datacenter=Falkenberg" --data-urlencode "platform=OpenVZ" --data-urlencode "hostname=web$(( $while_var2 + 1 )).$FQDN" --data-urlencode "rootpassword=$ROOTPASS" --data-urlencode "templatename=$TEMPLATE" --data-urlencode "disksize=$DISKSIZE" --data-urlencode "memorysize=$MEMORYSIZE" --data-urlencode "cpucores=$CPUCORES" https://api.glesys.com/server/create/ > services_details/web_server_$(( $while_var2 + 1 )).xml

while_var1=$[$while_var1-1]
done

# Extra vars
FS_VOLUMEID=`cat services_details/filestorage.xml  | xmlstarlet sel -t -v "/response/volume/volumeid"`
LB_ID=`cat services_details/lb.xml | xmlstarlet sel -t -v "/response/loadbalancer/loadbalancerid"` 
LB_IP=`cat services_details/lb.xml | xmlstarlet sel -t -v "/response/loadbalancer/ipaddress/item/ipaddress"`
DB_SERVERID=`cat services_details/db_server.xml |  xmlstarlet sel -t -v "/response/server/serverid"`


while_var1=$web_num
while [ $while_var1 -gt 0 ] 
do
while_var2=$(( $web_num - $while_var1 ))
WEB_SERVERID[$while_var2]=`cat services_details/web_server_$(( $while_var2 + 1 )).xml |  xmlstarlet sel -t -v "/response/server/serverid"`
while_var1=$[$while_var1-1]
done

# checking the status of all services before start.
secs=$((3 * 60))
while [ $secs -gt 0 ]; do
   minutes=$(($secs / 60))
   secs_2=$(($secs - $minutes * 60))
   echo -ne "The services can take up to 8 minutes to be all active. Please take a cup of coffee and wait: $minutes:$secs_2 \033[0K\r"
   sleep 1
   : $((secs--))
done
echo ""
echo -n " checking the status"
for i in {0..40}; do  echo -n "." ; sleep 0.05 ; done ; echo "."
# checking file-storage's status.
coutdown_=5
while [ $coutdown_ -gt 0 ]; do
FS_STATUS=`curl -sS -X POST --basic -u $API_USER:$API_KEY --data-urlencode "volumeid=$FS_VOLUMEID" https://api.glesys.com/filestorage/volumedetails/ |  xmlstarlet sel -t -v "/response/volume/status"`
if [ $FS_STATUS == "ready" ]; then
coutdown_=0
echo "File-storage is ready now"
curl -sS -X POST --basic -u $API_USER:$API_KEY --data-urlencode  "volumeid=$FS_VOLUMEID" https://api.glesys.com/filestorage/volumedetails/ > services_details/filestorage.xml
else 
echo "File-storage not ready yet. $coutdown_ attempts remain" ; wait_1
fi
   : $((coutdown_--))
done
if ! [ $FS_STATUS == "ready" ]; then
echo -e "Something went wrong the File-storage! \nPlease remove everything and start over. \nIf this problem appears again please contact support@glesys.se "  >&2; exit 1
fi

# checking servers status.
curl -sS -X POST --basic -u $API_USER:$API_KEY --data-urlencode "serverid=$DB_SERVERID" https://api.glesys.com/server/details/  | grep "<state/>" >  /dev/null 2>&1
if [[ $? -ne 0 ]] ; then
echo -e "Something went wrong with the database server! \nPlease remove everything and start over. \nIf this problem appears again please contact support@glesys.se "  >&2; exit 1
fi 
curl -sS -X POST --basic -u $API_USER:$API_KEY --data-urlencode "serverid=$DB_SERVERID" https://api.glesys.com/server/details/  > services_details/db_server.xml


while_var1=$web_num
while [ $while_var1 -gt 0 ] 
do
while_var2=$(( $web_num - $while_var1 ))
curl -sS -X POST --basic -u $API_USER:$API_KEY --data-urlencode "serverid=${WEB_SERVERID[$while_var2]}" https://api.glesys.com/server/details/  | grep "<state/>" >  /dev/null 2>&1
if [[ $? -ne 0 ]] ; then
echo -e "Something went wrong with the web server $(( $while_var2 + 1 )) ! \nPlease remove everything and start over. \nIf this problem appears again please contact support@glesys.se "  >&2; exit 1
fi 
curl -sS -X POST --basic -u $API_USER:$API_KEY --data-urlencode "serverid=${WEB_SERVERID[$while_var2]}" https://api.glesys.com/server/details/  > services_details/web_server_$(( $while_var2 + 1 )).xml
while_var1=$[$while_var1-1]
done


# adding web servers to filestorage accesslist.
FS_ACCESSLIST="${WEB_SERVERID[0]}"
while_var1=$(( $web_num - 1 ))
while [ $while_var1 -gt 0 ] 
do
while_var2=$(( $web_num - $while_var1 ))
FS_ACCESSLIST="${FS_ACCESSLIST},${WEB_SERVERID[$while_var2]}"
while_var1=$[$while_var1-1]
done
echo "Adding web servers to filestorage accesslist ........"
curl -sS -X POST --basic -u $API_USER:$API_KEY --data-urlencode "volumeid=$FS_VOLUMEID" --data-urlencode "accesslist=$FS_ACCESSLIST" https://api.glesys.com/filestorage/editvolume/ >  /dev/null 2>&1




##################
## Ansible vars ##
##################

	if ! [ -d ~/.ssh ]; then
       mkdir ~/.ssh
	fi;

echo "Addning servers IPs to ~/.ssh/known_hosts and fixing PTR"
db_server=`cat services_details/db_server.xml |  xmlstarlet sel -t -v "/response/server/iplist/item/ipaddress" | head -1 | awk 1 ORS=''`
# fixing PTR
curl -sS -X POST --basic -u $API_USER:$API_KEY --data-urlencode "data=db.$FQDN." --data-urlencode "ipaddress=$db_server" https://api.glesys.com/ip/setptr/ >  /dev/null 2>&1
ssh-keygen -R $db_server >  /dev/null 2>&1
echo "adding $db_server to ~/.ssh/known_hosts"
ssh-keyscan -H $db_server >> ~/.ssh/known_hosts 
while_var1=$web_num
while [ $while_var1 -gt 0 ] 
do
while_var2=$(( $web_num - $while_var1 ))
web_servsers[$while_var2]=`cat services_details/web_server_$(( $while_var2 + 1 )).xml |  xmlstarlet sel -t -v "/response/server/iplist/item/ipaddress" | head -1 | awk 1 ORS=''`
# fixing PTR
curl -sS -X POST --basic -u $API_USER:$API_KEY --data-urlencode "data=web$(( $while_var2 + 1 )).$FQDN." --data-urlencode "ipaddress=${web_servsers[$while_var2]}" https://api.glesys.com/ip/setptr/ >  /dev/null 2>&1
ssh-keygen -R ${web_servsers[$while_var2]} > /dev/null 2>&1
echo "adding ${web_servsers[$while_var2]} to ~/.ssh/known_hosts"
ssh-keyscan -H ${web_servsers[$while_var2]} >> ~/.ssh/known_hosts 
while_var1=$[$while_var1-1]
done

# Setting up the load balancer
echo "Setting up the load balancer........"
echo "Adding BackEnd....."
curl -sS -X POST --basic -u $API_USER:$API_KEY --data-urlencode "loadbalancerid=$LB_ID" --data-urlencode "name=$LB_ID.back" --data-urlencode "mode=http" https://api.glesys.com/loadbalancer/addbackend/ >  /dev/null 2>&1
sleep 1
while_var1=$web_num
while [ $while_var1 -gt 0 ] 
do
while_var2=$(( $web_num - $while_var1 ))
echo "Adding target $(( $while_var2 + 1 )) ....."
curl -sS -X POST --basic -u $API_USER:$API_KEY --data-urlencode "loadbalancerid=$LB_ID" --data-urlencode "backendname=$LB_ID.back" --data-urlencode "ipaddress=${web_servsers[$while_var2]}" --data-urlencode "port=80" --data-urlencode "name=web$(( $while_var2 + 1 ))" --data-urlencode "weight=1" https://api.glesys.com/loadbalancer/addtarget/ >  /dev/null 2>&1
sleep 1
while_var1=$[$while_var1-1]
done
echo "Adding FrontEnd....."
curl -sS -X POST --basic -u $API_USER:$API_KEY --data-urlencode "loadbalancerid=$LB_ID" --data-urlencode "name=$LB_ID.front" --data-urlencode "port=80" --data-urlencode "backendname=$LB_ID.back" https://api.glesys.com/loadbalancer/addfrontend/ >  /dev/null 2>&1


nfs_mount=$FS_VOLUMEID
www_domain=$FQDN
ftp_user=$FTP_USERNAME
############################
for i in {0..40}; do  echo -n "#" ; sleep 0.05 ; done ; echo "#"

##########################

while_var1=$web_num

while [ $while_var1 -gt 0 ]
do
while_var2=$(( $web_num - $while_var1 ))
FTPUSERPASS_PLAIN[$while_var2]=`pwgen -Bs 15 1`
FTPUSERPASS[$while_var2]=`python -c 'from passlib.hash import sha512_crypt; print sha512_crypt.encrypt("'$SSHUSERPASS_PLAIN'")'`
while_var1=$[$while_var1-1]
done
##########################
DEBIANMYSQLPASS=`pwgen -Bs 15 1`
#########################
WP_DBUSER_PASS=`pwgen -Bs 15 1`
WP_USER_PASS=`pwgen -Bs 15 1`
#################################
	# Removing old vars files
	if [ -d host_vars ]; then
       rm host_vars/*
	fi;
	if [ -d group_vars ]; then
       rm group_vars/*
	fi;
	mkdir -p group_vars;
	mkdir -p host_vars;
#################################
	echo "[GleSYS_WP:children]" > hosts.yml
	echo "database_server" >> hosts.yml
	echo "web_servers" >> hosts.yml
	echo "[database_server:vars]" >> hosts.yml
	echo "db_server="true"" >> hosts.yml
	echo "" >> hosts.yml
	echo "[database_server]" >> hosts.yml
	echo "$db_server" >> hosts.yml
	echo "" >> hosts.yml
	echo "[web_servers]" >> hosts.yml
	while_var1=$web_num
	while [ $while_var1 -gt 0 ]
	do
	while_var2=$(( $web_num - $while_var1 ))
	echo ${web_servsers[$while_var2]} >> hosts.yml
	while_var1=$[$while_var1-1]
	done
	echo "" >> hosts.yml

####################################
        while_var1=$web_num
        while [ $while_var1 -gt 0 ]
        do
        while_var2=$(( $web_num - $while_var1 ))

		echo "---" > host_vars/${web_servsers[$while_var2]}
		echo "ansible_ip: ${web_servsers[$while_var2]}" >> host_vars/${web_servsers[$while_var2]}
		echo "ansible_ftp_pass: ${FTPUSERPASS[$while_var2]}" >> host_vars/${web_servsers[$while_var2]}

        while_var1=$[$while_var1-1]
        done
##################################
		echo "---" > host_vars/$db_server
		echo "ansible_ip: $db_server" >> host_vars/$db_server
##################################

	echo "---" > group_vars/all
	echo "ansible_ssh_user: root" >> group_vars/all
	echo "ansible_ssh_pass: $ROOTPASS" >> group_vars/all
	echo "ansible_connection: ssh " >> group_vars/all
	echo "ansible_www_domain: $www_domain" >> group_vars/all
	echo "ansible_www_user: $ftp_user" >> group_vars/all
	echo "filestorage_ID: $nfs_mount" >> group_vars/all
	echo "ansible_dbname: db_$wp_user" >> group_vars/all
	echo "ansible_dbuser: $wp_user" >> group_vars/all
	echo "ansible_dbuser_pass: $WP_DBUSER_PASS" >> group_vars/all
	echo "ansible_wp_title: $wp_title" >> group_vars/all
	echo "ansible_wp_user: $wp_user" >> group_vars/all
	echo "ansible_wp_pass: $WP_USER_PASS" >> group_vars/all
	echo "ansible_wp_email: $wp_email" >> group_vars/all

	ansible-playbook -i hosts.yml install.yml 
#################################
echo "Domain name: $www_domain"
echo "The services that have been created in $DATACENTER are:"
echo "Database server: db.$FQDN / $db_server"
while_var1=$web_num
while [ $while_var1 -gt 0 ] 
do
while_var2=$(( $web_num - $while_var1 ))
echo "Web server: web$(( $while_var2 + 1 )).$FQDN / ${web_servsers[$while_var2]} "
echo "Web server $(( $while_var2 + 1 )) SSH-user: $ftp_user"
echo "Web server $(( $while_var2 + 1 )) password: ${FTPUSERPASS_PLAIN[$while_var2]}"
while_var1=$[$while_var1-1]
done
echo ""
echo "server's root password: $ROOTPASS"
echo "Server's OS: $TEMPLATE"
echo "Load balancer: lb-$FQDN / $LB_IP "
echo "File-storage: fs-$FQDN / $nfs_mount.cloud.glesys.net "
echo "#######################################################"
echo "WordPress info:"
echo "Wordpress title: $wp_title"
echo "Wordpress username: $wp_user"
echo "Wordpress password: $WP_USER_PASS"
echo "Wordpress E-mail: $wp_email"
echo "Wordpress database name: db_$wp_user"
echo "Wordpress database user: $wp_user"
echo "Wordpress database password: $WP_DBUSER_PASS"
echo "#######################################################"


###########################################

# working with domain name
fqdn_ct=`echo "$FQDN" | tr '.' '\n' | wc -l`
main_domain=`echo "$FQDN" | rev | cut -d'.' -f1,2 | rev`
sub_domain=`echo "$FQDN" | tr '.' '\n' | head -$(( $fqdn_ct - 2 ))  | tr '\n' '\.' | rev | cut -c 2- | rev`


#Check if API Credentials has access to the domains
API_CHECK_CODE=`curl -sS -X POST --basic -u $API_USER:$API_KEY https://api.glesys.com/domain/list/ | xmlstarlet sel -t -v "/response/status/code"`
if [ "$API_CHECK_CODE" -ne 200 ]; then
        ERRORCODE=`curl -sS -X POST --basic -u $API_USER:$API_KEY https://api.glesys.com/domain/list/ |xmlstarlet sel -t -v "/response/status/text" `
        echo "API has no access to the dmoains in this project"
        exit 1
fi
echo "API Access to the domains are OK."


# checking if the domain is register in the cloud account
curl -sS -X POST --basic -u $API_USER:$API_KEY https://api.glesys.com/domain/list/ | grep ">$main_domain<" >  /dev/null 2>&1
if [[ $? -ne 0 ]] ; then
   echo "Domain is not register in the cloud account"
   echo "If you want to register your domain please check https://glesys.com/services/domains "
   domain_in_account="no"
else
	echo "Domain is registered"
   domain_in_account="yes"
fi
if [[ $sub_domain == "www" ]] ; then
sub_domain=""
fi

#check if there is a DNS-record for the sub_domain.
if [[ $domain_in_account == "yes" ]] && ! [[ -z $sub_domain ]] ; then
	curl -sS -X POST --basic -u $API_USER:$API_KEY --data-urlencode "domainname=$main_domain" https://api.glesys.com/domain/listrecords/ | grep ">$sub_domain<" >  /dev/null 2>&1
	if [[ $? -eq 0  ]] ; then
		echo "There is already a DNS-record for $FQDN. You need to fix that manually and make it point to  $LB_IP"
		record_is_exist="yes"
	else
		record_is_exist="no"
	fi
fi
if [[ -z $sub_domain ]] ; then
	sub_domain="www"
fi

	


if [[ $domain_in_account == "yes" ]] ; then
	main_domain_record_ip=`curl -sS -X POST --basic -u $API_USER:$API_KEY --data-urlencode "domainname=$main_domain" https://api.glesys.com/domain/listrecords/ | xmlstarlet sel -t  -m "/response/records/item[host='@'][type='A']" -v data`
	sub_domain_record_ip=`curl -sS -X POST --basic -u $API_USER:$API_KEY --data-urlencode "domainname=$main_domain" https://api.glesys.com/domain/listrecords/ | xmlstarlet sel -t  -m "/response/records/item[host='$sub_domain'][type='A']" -v data`
fi

if  [[ $domain_in_account == "yes" ]] && ! [[ $main_domain_record_ip == "127.0.0.1" ]] && ! [[ -z $main_domain_record_ip ]] && [[ $sub_domain == "www" ]]; then
	echo "There is already a DNS-record for $main_domain. You need to fix that manually :)"
fi

if [[ $domain_in_account == "yes" ]] && [[ $main_domain_record_ip == "127.0.0.1" ]] ; then
	main_domain_record_id=`curl -sS -X POST --basic -u $API_USER:$API_KEY --data-urlencode "domainname=$" https://api.glesys.com/domain/listrecords/ | xmlstarlet sel -t  -m "/response/records/item[host='@'][type='A']" -v recordid`
	curl -sS -X POST --basic -u $API_USER:$API_KEY --data-urlencode "recordid=$main_domain_record_id" --data-urlencode "data=$LB_IP"  https://api.glesys.com/domain/updaterecord/ >  /dev/null 2>&1
	echo "Updating the DNS-record for $main_domain to $LB_IP "
fi
if [[ $domain_in_account == "yes" ]] && [[ -z $main_domain_record_ip ]] && [[ $sub_domain == "www" ]] ; then
	curl -sS -X POST --basic -u $API_USER:$API_KEY --data-urlencode "domainname=$main_domain" --data-urlencode "host=@" --data-urlencode "type=A" --data-urlencode "data=$LB_IP" https://api.glesys.com/domain/addrecord/ >  /dev/null 2>&1
	echo "Adding the DNS-record for $main_domain to $LB_IP "
fi

if [[ $domain_in_account == "yes" ]] && [[ $sub_domain == "www" ]] && [[ $sub_domain_record_ip == "127.0.0.1" ]] ; then
	sub_domain_record_id=`curl -sS -X POST --basic -u $API_USER:$API_KEY --data-urlencode "domainname=$main_domain" https://api.glesys.com/domain/listrecords/ | xmlstarlet sel -t  -m "/response/records/item[host='$sub_domain'][type='A']" -v recordid`
	curl -sS -X POST --basic -u $API_USER:$API_KEY --data-urlencode "recordid=$sub_domain_record_id" --data-urlencode "data=$LB_IP"  https://api.glesys.com/domain/updaterecord/ >  /dev/null 2>&1
	echo "Updating the DNS-record for www.$main_domain to $LB_IP "
fi
if [[ $domain_in_account == "yes" ]] && [[ $sub_domain == "www" ]] && [[ -z $sub_domain_record_ip  ]] ; then
	curl -sS -X POST --basic -u $API_USER:$API_KEY --data-urlencode "domainname=$main_domain" --data-urlencode "host=$sub_domain" --data-urlencode "type=A" --data-urlencode "data=$LB_IP" https://api.glesys.com/domain/addrecord/ >  /dev/null 2>&1
	echo "adding the DNS-record for www.$main_domain to $LB_IP "
fi

if [[ $domain_in_account == "yes" ]] && [[ $record_is_exist == "no" ]] ; then
	curl -sS -X POST --basic -u $API_USER:$API_KEY --data-urlencode "domainname=$main_domain" --data-urlencode "host=$sub_domain" --data-urlencode "type=A" --data-urlencode "data=$LB_IP" https://api.glesys.com/domain/addrecord/ >  /dev/null 2>&1
	echo "adding the DNS-record for $FQDN to $LB_IP "
fi

echo "If anything fails when the ansible-playbook runs, please run ( ansible-playbook -i hosts.yml install.yml  ) and see if it solve the problem!!"

exit 0
