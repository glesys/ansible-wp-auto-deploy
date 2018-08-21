# GleSYS API/Ansible Demo for deplopying a WordPress environment.

This is an automated procedure to:

  * Create and config a database server.
  * Create and config 2 or more web servers.
  * Create and config a loadbalancer to balance the trafic between the web servers.
  * Create and config a file storage valume and share it with the web servers.
  * Install WordPress, base install with Ansible (http://docs.ansible.com)
  * Set DNS record for the specified domain.

..............................................................

## Installation : 

#### Step 1 – API Key
  * create a GleSYS API key with IP, DOMAIN and SERVER privilegies (Permissions / Allow all on Domain, IP, load balancer, filestorage and Server)
  * use a domain which is maintained on your GleSYS project  (record should not pre-exist) if it does it wouldn't be changed.
  * If the domain is not maintained on your GleSYS project you will need to an A record for this cluster manulally.

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

##### Install these on Debian/Ubuntu

	apt-get install python-dev build-essential python-pip pwgen xmlstarlet curl sshpass nmap python-passlib
	pip install ansible

##### Install these on MacOS X (using Homebrew)

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
	cd cluster/

Finally, run the script ./deploy.sh (be sure to meet the requirements above) and don't forget to put your API Credentials :

```
	API_USER="PLACE YOUR GLESYS PROJECT ID HERE" \
	API_KEY="PLACE YOUR API KEY HERE" \
	./deploy.sh USERNAME FQDN  # (for example: ./deploy.sh wp_user blog.domain.com)
```
## This will be installed on the remote host

	- Two or more web servers
		Debian 9 as template
		Apache 2.4
		PHP 7.0
		Postfix (SMTP)
		Latest WordPress (post-setup config is done with http://wp-cli.org )
	
	- One database server
		debian 9 as template
		MariaDB 10
	
	- One load balancer
	

#Support
If you need further help send an email to support@glesys.se
