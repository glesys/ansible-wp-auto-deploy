# GleSYS API/Ansible Demo

This is an automated procedure to:

  * create a server with provided FQDN
  * set DNS record for the specified domain
  * set PTR record to the newly created servers IP
  * install WordPress, base install with Ansible (http://docs.ansible.com)


## Installation


#### Step 1 – API Key

   * create a GleSYS API key with IP, DOMAIN and SERVER privilegies (`Permissions / Allow all on Domain, IP and Server`)
   * use a domain which is maintained on your GleSYS account (record should not pre-exist)


#### Step 2 - Requirements (where you initiate the script)

   * Ansible 2
   * Sshpass
   * PWGen
   * XMLStarlet
   * Curl
   * Python Passlib Library
   * Nmap
   * Git-core

Below are installation instructions for Debian/Ubuntu and MacOS X. However, it's possible to keep on using your preferred OS, just find the above packages and you'll be good to go.


###### Install these on Debian/Ubuntu


	apt-get install python-dev build-essential python-pip pwgen xmlstarlet curl sshpass nmap python-passlib
	pip install ansible


###### Install these on MacOS X (using Homebrew)


	brew install ansible
	brew install xmlstarlet
	brew install nmap
	brew install pwgen
	brew create https://sourceforge.net/projects/sshpass/files/sshpass/1.06/sshpass-1.06.tar.gz --force
	brew install sshpass
	brew install python
	pip install passlib


#### Step 3 - Download and run the script

First download the script:


	git clone https://github.com/GleSYS/wp-auto-deploy.git

	cd single/

Finally, run the script ./deploy.sh (be sure to meet the requirements above) and don't forget to put your API Credentials :

```
	API_USER="PLACE YOUR GLESYS PROJECT ID HERE" \
	API_KEY="PLACE YOUR API KEY HERE" \
	./deploy.sh USERNAME FQDN  # (for example: ./deploy.sh wp_user blog.domain.com)
```


## This will be installed on the remote host


	Debian 9 as template
	Apache 2.4
	PHP 7.0
	Postfix (SMTP)
	Latest WordPress (post-setup config is done with http://wp-cli.org )
	MariaDB 10


## GleSYS API calls used for this demo


   * [Create Server](https://github.com/GleSYS/API/wiki/Full-API-Documentation#servercreate)
   * [List Domain Records](https://github.com/GleSYS/API/wiki/Full-API-Documentation#domainlistrecords)
   * [Add Domain Record](https://github.com/GleSYS/API/wiki/Full-API-Documentation#domainaddrecord)
   * [Update PTR for IP](https://github.com/GleSYS/API/wiki/Full-API-Documentation#ipsetptr)


## Support

   * if you need further help send an email to support@glesys.se
