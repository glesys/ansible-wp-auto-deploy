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
        echo "syntax is: ./deploy.sh USER FQDN (./deploy.sh username blog.domain.com)"
        exit
fi



#Check if dependencies are in place.
for BINARY in pwgen ansible-playbook xmlstarlet curl sshpass nmap ; do
        DEPS=`which $BINARY`
        if [ "$?" -ne 0 ]; then
                echo "$BINARY is not installed, please read README.md for dependencys"
                exit 0
        fi
done

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

#Add site Variables
SSHUSER=$FTP_USERNAME
SSHUSERPASS_PLAIN=`pwgen -Bs 15 1`
#Encrypt user password (linux compat.)
SSHUSERPASS=`python -c 'from passlib.hash import sha512_crypt; print sha512_crypt.encrypt("'$SSHUSERPASS_PLAIN'")'`
MYSQLPASS=`pwgen -Bs 15 1`
DBNAME=db_$SSHUSER
DBUSER=$SSHUSER
DBPASS=`pwgen -Bs 15 1`

#Wordpress Variables
TITLE="WordPress Demo"
ADMINUSER=$SSHUSER
ADMINPASS=$SSHUSERPASS_PLAIN
EMAIL="$FTP_USERNAME@$FQDN"

#API call to retrieve list of records for the domain.
curl -sS -X POST -d "domainname="$DOMAIN"" -k --basic -u $API_USER:$API_KEY https://api.glesys.com/domain/listrecords/ > server.xml
#Run function to validate the response
validate_xml

#Check if a record already exist for the subdomain and exit if it does.
if grep --quiet "<host>""$HOSTNAME""</host>" server.xml; then
   echo "Subdomain already exist, we wont edit a record in this demo. Please use a subdomain that does not previously exist."
   exit 0
fi

#Create Server and store IP
echo "Creating Server"
curl -sS -X POST -d "datacenter="$DATACENTER"&platform="$PLATFORM"&hostname="$HOSTNAME"."$DOMAIN"&templatename=$TEMPLATE&disksize="$DISKSIZE"&memorysize="$MEMORYSIZE"&cpucores="$CPUCORES"&rootpassword="$ROOTPASS"" -k --basic -u $API_USER:$API_KEY https://api.glesys.com/server/create/ > server.xml
#Run function to validate the response
validate_xml

#extract ipv4 info from server.xml
xmlstarlet sel -t -c "/response/server/iplist/item[version=4]" server.xml > serverip.xml

#Parse IP from serverip.xml output
SERVERIP=`xmlstarlet sel -t -v "/item/ipaddress" serverip.xml`

#Create A-Record with Server IP.
echo "Creating A-record for subdomain"
curl -sS -X POST -d "domainname="$DOMAIN"&host="$HOSTNAME"&type=A&data="$SERVERIP"" -k --basic -u $API_USER:$API_KEY https://api.glesys.com/domain/addrecord/ > server.xml
#Run function to validate the response
validate_xml

#Set PTR for the IP
echo "Setting PTR for the IP."
curl -sS -X POST -d "ipaddress="$SERVERIP"&data="$HOSTNAME"."$DOMAIN"." -k --basic -u $API_USER:$API_KEY https://api.glesys.com/ip/setptr/ > server.xml
#Run function to validate the response
validate_xml

#Determine When Server Is Up:
echo "Waiting for server to be reachable, this might take a while.."
# Maximum number to try.
((count = 100))
while [[ $count -ne 0 ]] ; do
    sleep 5
    nmap -p22 $SERVERIP -oG - | grep -q 22/open
    rc=$?
    if [[ $rc -eq 0 ]] ; then
	# If okay, flag to exit loop.
        ((count = 1))
    fi
    # So we don't go forever.
    ((count = count - 1))
done
# Make final determination.
if [[ $rc -eq 0 ]] ; then

    echo "The Server is up. We can continue with ansible"

		#ANSIBLE VARIABLES
                echo "server1 ansible_host=$SERVERIP" > hosts.yml
                echo "[servers]" >> hosts.yml
                echo "server1" >> hosts.yml

                echo "---" > global_vars.yml
		echo "ansible_ssh_pass: $ROOTPASS" >> global_vars.yml
                echo "ansible_ip: $SERVERIP" >> global_vars.yml

                echo "ansible_www_user: $SSHUSER" >> global_vars.yml
                echo "ansible_user_pass: $SSHUSERPASS" >> global_vars.yml
                echo "ansible_www_domain: $HOSTNAME.$DOMAIN" >> global_vars.yml
		echo "ansible_hostname: $HOSTNAME" >> global_vars.yml
                echo "ansible_mysql_password: $MYSQLPASS" >> global_vars.yml

                echo "ansible_dbname: $DBNAME" >> global_vars.yml
                echo "ansible_dbuser: $DBUSER" >> global_vars.yml
                echo "ansible_dbuser_pass: $DBPASS" >> global_vars.yml

                echo "ansible_wp_title: $TITLE" >> global_vars.yml
                echo "ansible_wp_user: $ADMINUSER" >> global_vars.yml
                echo "ansible_wp_pass: $ADMINPASS" >> global_vars.yml
                echo "ansible_wp_email: $EMAIL" >> global_vars.yml

		#Run Ansible, root password is provided by the "ansible_ssh_pass" variable
		ansible-playbook -i hosts.yml install-lamp-wp.yml -u root

                #IMPORTANT OUTPUT
                echo "-------------"
                echo "Server Info"
                echo "Server ip: $SERVERIP"
                echo "root password: $ROOTPASS"
                echo "-------------"
                echo "Regular ssh/ftp user"
                echo "ssh user: $SSHUSER"
                echo "ssh password: $SSHUSERPASS_PLAIN"
                echo "-------------"
                echo "Wordpress login (http://"$HOSTNAME"."$DOMAIN"/wp-login.php)"
                echo "wordpress user: $ADMINUSER"
                echo "Wordpress password is: $ADMINPASS"
                echo "-------------"

else
    echo "Server did not respond in time, SSH is not reachable"
fi
