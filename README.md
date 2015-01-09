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

   * Ansible 1.7
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
	brew install https://raw.github.com/eugeneoden/homebrew/eca9de1/Library/Formula/sshpass.rb (Homebrew doesn't want to merge this https://github.com/Homebrew/homebrew/pull/9577 but it's what Ansible uses)
	brew install python
	pip install passlib


#### Step 3 - Download and run the script

First download the script:


	git clone https://github.com/GleSYS/wp-auto-deploy.git


Then add your API credentials to deploy.sh where it says:


	#API Credentials
	USER=PLACE_YOUR_ACCOUNT_HERE
	KEY=PLACE_YOUR_KEY_HERE


Finally, run the script (be sure to meet the requirements above):


	./deploy.sh FQDN (for example: ./deploy.sh blog.domain.com)


## This will be installed on the remote host


   * Debian 7 as template (you can edit the Ansible Playbook to make it compatible with other distributions)
   * Apache 2.2
   * MySQL 5.5
   * PHP 5.4.0
   * Postfix (SMTP)
   * ProFTPd (FTP Server)
   * Latest WordPress (post-setup config is done with http://wp-cli.org)


## GleSYS API calls used for this demo


   * [Create Server](https://github.com/GleSYS/API/wiki/Full-API-Documentation#servercreate)
   * [List Domain Records](https://github.com/GleSYS/API/wiki/Full-API-Documentation#domainlistrecords)
   * [Add Domain Record](https://github.com/GleSYS/API/wiki/Full-API-Documentation#domainaddrecord)
   * [Update PTR for IP](https://github.com/GleSYS/API/wiki/Full-API-Documentation#ipsetptr)


## Support


   * watch this instructional video: [Server Provisioning with GleSYS API & Ansible](http://vimeo.com/116329707)
   * if you need further help send an email to support@glesys.se
